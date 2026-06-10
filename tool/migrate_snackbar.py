#!/usr/bin/env python3
"""Migrate FeedbackHelper.showSnackBar(SnackBar(content: Text(...))) to showSuccess/showError."""
import re
from pathlib import Path

ERROR_HINTS = (
    'friendlyError', 'Erro', 'erro', 'Não foi possível', 'Nao foi possivel',
    'obrigatório', 'obrigatorio', 'Preencha', 'Selecione', 'precisa de',
    'Tente novamente', 'Nao foi', 'não foi', 'vazio', 'Vazio', 'invalido',
    'inválido', 'EagleTokens.bad', 'Não foi possível concluir',
    'Não foi possível identificar', 'Não foi possível criar', 'Não foi possível gerar',
    'Não foi possível aplicar', 'Não foi possível enviar', 'Saúde não disponível',
    'Permita o microfone', 'Informe a descrição', 'Selecione aluno',
    'Cole uma URL válida', 'Você ainda não possui',
)

SUCCESS_HINTS = (
    'sucesso', 'copiado', 'confirmada', 'criada', 'atualizado', 'enviado',
    'adicionad', 'excluído', 'excluido', 'registrad', 'compartilhad',
    'aceita', 'publicação', 'publicacao', 'gerada', 'atualizada', 'definido',
    'criado', 'descartada', 'PDF pronto', 'Inscrição', 'Link iCal copiado',
    'Agendamento excluído', 'Medida adicionada', 'Recorde adicionado',
    'Mensagem copiada', 'Oferta criada', 'Aluno atualizado', 'Convite copiado',
    'Link copiado', 'Carteira atualizada', 'Chave PIX copiada', 'Foto atualizada',
    'Perfil do aluno atualizado', 'Conta excluida', 'Conta excluída',
    'Nova medida registrada', 'Dieta gerada', 'Publicação criada',
    'Video proprio', 'Vídeo enviado', 'Tarefa concluída', 'Sugestão descartada',
    'Status atualizado', 'EagleTokens.good', 'Convertido', 'Follow-up',
    'Exercicio excluido', 'Interação registrada', 'Trial Enterprise',
    'Link de assinatura copiado', 'Curadoria marcada', 'Sugestao registrada',
    'Sugestão copiada', 'Todas marcadas como lidas', 'Oferta aceita',
    'Oferta recusada', 'progressaoSavedForReviewSnack', 'aluno(s) marcado(s)',
    'Sugestao ignorada',
)


def classify(text_expr: str, snack_inner: str) -> str:
    blob = text_expr + snack_inner
    if 'friendlyError' in blob or 'EagleTokens.bad' in blob:
        return 'showError'
    for hint in ERROR_HINTS:
        if hint in blob:
            return 'showError'
    for hint in SUCCESS_HINTS:
        if hint in blob:
            return 'showSuccess'
    if 'EagleTokens.good' in blob:
        return 'showSuccess'
    return 'showInfo'


def find_matching_paren(source: str, open_index: int) -> int:
    depth = 0
    in_single = in_double = False
    i = open_index
    while i < len(source):
        ch = source[i]
        if in_single:
            if ch == "'" and source[i - 1] != '\\':
                in_single = False
        elif in_double:
            if ch == '"' and source[i - 1] != '\\':
                in_double = False
        elif ch == "'":
            in_single = True
        elif ch == '"':
            in_double = True
        elif ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError('Unbalanced parens')


def extract_text_expr(snack_inner: str) -> str | None:
    marker = re.search(r'content:\s*(?:const\s+)?Text\s*\(', snack_inner)
    if not marker:
        return None
    start = marker.end() - 1
    end = find_matching_paren(snack_inner, start)
    return snack_inner[marker.end():end].strip()


def migrate_source(source: str) -> str:
    needle = 'FeedbackHelper.showSnackBar'
    updated = source
    while True:
        idx = updated.find(needle)
        if idx == -1:
            break
        call_start = idx
        paren_start = updated.find('(', idx)
        paren_end = find_matching_paren(updated, paren_start)
        call = updated[call_start:paren_end + 1]

        inner = updated[paren_start + 1:paren_end]
        snack_match = re.search(r'(?:const\s+)?SnackBar\s*\(', inner)
        if not snack_match:
            updated = updated[:call_start] + updated[paren_end + 1:]
            continue
        snack_start = snack_match.start()
        snack_paren = inner.find('(', snack_match.start())
        snack_end = find_matching_paren(inner, snack_paren)
        snack_call = inner[snack_start:snack_end + 1]
        snack_inner = inner[snack_paren + 1:snack_end]

        ctx_part = inner[:snack_start].strip().rstrip(',')
        text_expr = extract_text_expr(snack_inner)
        if text_expr is None:
            break

        method = classify(text_expr, snack_inner)
        operacao = 'placement: FeedbackPlacement.operacaoTop' in call
        if operacao:
            method = method.replace('show', 'showOperacao', 1)

        replacement = f'FeedbackHelper.{method}({ctx_part}, {text_expr});'
        updated = updated[:call_start] + replacement + updated[paren_end + 1:]

    return updated


def main() -> None:
    root = Path(__file__).resolve().parents[1] / 'lib' / 'features'
    changed: list[str] = []
    for path in sorted(root.rglob('*.dart')):
        original = path.read_text(encoding='utf-8')
        try:
            updated = migrate_source(original)
        except ValueError as exc:
            print(f'SKIP {path}: {exc}')
            continue
        if updated != original:
            path.write_text(updated, encoding='utf-8')
            changed.append(str(path.relative_to(root.parent.parent)))
    print(f'Changed {len(changed)} files')
    for name in changed:
        print(name)


if __name__ == '__main__':
    main()
