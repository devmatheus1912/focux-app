import { test as base, expect, Page } from '@playwright/test';

type Errors = string[];

/**
 * Flutter Web (CanvasKit) hides DOM by default. Enable semantics tree so
 * Playwright can find inputs/buttons via aria roles and labels.
 *
 * Strategy:
 *  1. Click the invisible <flt-semantics-placeholder> Flutter renders.
 *  2. Wait for <flt-semantics-host> to materialize.
 *  3. Fall back to dispatching the activation event manually.
 */
export async function enableFlutterSemantics(page: Page) {
  await page.evaluate(async () => {
    const tryClick = () => {
      const ph = document.querySelector('flt-semantics-placeholder')
        || document.querySelector('flt-glass-pane')?.shadowRoot?.querySelector('flt-semantics-placeholder');
      if (ph) (ph as HTMLElement).click();
    };
    tryClick();

    // Dispatch real DOM UI events. Flutter Web reads MouseEvent/PointerEvent
    // helpers such as getModifierState() while enabling semantics.
    const target =
      document.querySelector('flt-semantics-placeholder') ||
      document.querySelector('flt-glass-pane');
    if (target) {
      const dispatchActivationEvent = (type: string) => {
        const common = {
          bubbles: true,
          cancelable: true,
          composed: true,
          view: window,
          clientX: 1,
          clientY: 1,
          screenX: 1,
          screenY: 1,
          button: 0,
          buttons: type.endsWith('down') ? 1 : 0,
        };

        if (type.startsWith('pointer') && 'PointerEvent' in window) {
          target.dispatchEvent(new PointerEvent(type, {
            ...common,
            pointerId: 1,
            pointerType: 'mouse',
            isPrimary: true,
          }));
          return;
        }

        target.dispatchEvent(new MouseEvent(type, common));
      };

      ['pointerdown', 'pointerup', 'mousedown', 'mouseup', 'click'].forEach(dispatchActivationEvent);
    }

    // poll briefly for semantics host
    for (let i = 0; i < 20; i++) {
      const has = document.querySelector('flt-semantics-host')
        || document.querySelector('[role="textbox"]')
        || document.querySelector('[aria-label]');
      if (has) return;
      await new Promise((r) => setTimeout(r, 100));
    }
  });
}

/**
 * Auto-rewrite goto() to use hash routing for Flutter Web GoRouter,
 * then enable Flutter accessibility semantics.
 */
function patchGotoForFlutterWeb(page: Page) {
  const original = page.goto.bind(page);
  (page as any).goto = async (url: string, opts?: any) => {
    if (typeof url === 'string') {
      if (!/^https?:\/\//i.test(url) && !url.startsWith('/#') && url.startsWith('/')) {
        url = '/#' + url;
      } else if (!/^https?:\/\//i.test(url) && !url.startsWith('#') && !url.startsWith('/')) {
        url = '/#/' + url;
      }
    }
    const resp = await original(url, opts);
    // give Flutter time to bootstrap
    await page.waitForTimeout(800);
    await enableFlutterSemantics(page);
    return resp;
  };
}

export const test = base.extend<{ errors: Errors }>({
  errors: async ({}, use) => {
    const errors: Errors = [];
    await use(errors);
  },
  page: async ({ page, errors }, use) => {
    patchGotoForFlutterWeb(page);

    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        const text = msg.text();
        if (
          text.includes('flutter_service_worker') ||
          text.includes('Synthetic package output') ||
          text.includes('was tree-shaken') ||
          (text.includes('Failed to load resource') && text.includes('chrome-extension')) ||
          text.includes('Failed to load resource: the server responded with a status of 401') ||
          text.includes('Failed to load resource: the server responded with a status of 404')
        ) return;
        errors.push(`CONSOLE: ${text}`);
      }
    });

    page.on('pageerror', (err) => {
      errors.push(`PAGEERROR: ${err.message}`);
    });

    page.on('response', async (resp) => {
      const status = resp.status();
      const url = resp.url();
      if (!url.includes('/api/')) return;
      if (status >= 500) errors.push(`HTTP ${status} ${resp.request().method()} ${url}`);
      if (status === 403 && !url.includes('/api/auth/')) {
        errors.push(`HTTP 403 ${resp.request().method()} ${url}`);
      }
    });

    await use(page);

    if (errors.length) {
      throw new Error(
        `Console/network errors detected during test:\n - ${errors.join('\n - ')}`,
      );
    }
  },
});

export { expect };
