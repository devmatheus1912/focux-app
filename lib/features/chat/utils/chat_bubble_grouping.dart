import 'package:flutter/material.dart';

import '../data/chat_repository.dart';

/// Visual cluster position for iOS-style stacked bubbles.
enum ChatBubbleGroupSlot { single, first, middle, last }

const Duration _chatBubbleGroupWindow = Duration(minutes: 5);

const double chatBubbleRadiusOuter = 18;
const double chatBubbleRadiusTight = 6;

bool chatMessagesGroupVisually(
  ChatMsg older,
  ChatMsg newer, {
  required bool Function(ChatMsg msg) isMine,
}) {
  if (isMine(older) != isMine(newer)) return false;
  if (older.remetente != newer.remetente) return false;
  if (older.deletedAt != null || newer.deletedAt != null) return false;
  final gap = newer.enviadoEm.difference(older.enviadoEm);
  if (gap.isNegative || gap > _chatBubbleGroupWindow) return false;
  return true;
}

ChatBubbleGroupSlot resolveChatBubbleGroupSlot({
  required ChatMsg msg,
  required ChatMsg? older,
  required ChatMsg? newer,
  required bool Function(ChatMsg msg) isMine,
  required bool Function(ChatMsg msg) isSystem,
}) {
  if (isSystem(msg)) return ChatBubbleGroupSlot.single;

  final groupsWithOlder =
      older != null &&
      !isSystem(older) &&
      chatMessagesGroupVisually(older, msg, isMine: isMine);
  final groupsWithNewer =
      newer != null &&
      !isSystem(newer) &&
      chatMessagesGroupVisually(msg, newer, isMine: isMine);

  if (!groupsWithOlder && !groupsWithNewer) {
    return ChatBubbleGroupSlot.single;
  }
  if (!groupsWithOlder && groupsWithNewer) {
    return ChatBubbleGroupSlot.first;
  }
  if (groupsWithOlder && groupsWithNewer) {
    return ChatBubbleGroupSlot.middle;
  }
  return ChatBubbleGroupSlot.last;
}

BorderRadius chatBubbleBorderRadius({
  required bool mine,
  required ChatBubbleGroupSlot slot,
}) {
  const o = chatBubbleRadiusOuter;
  const t = chatBubbleRadiusTight;

  if (mine) {
    switch (slot) {
      case ChatBubbleGroupSlot.single:
        return BorderRadius.only(
          topLeft: Radius.circular(o),
          topRight: Radius.circular(o),
          bottomLeft: Radius.circular(o),
          bottomRight: Radius.circular(t),
        );
      case ChatBubbleGroupSlot.first:
        return BorderRadius.only(
          topLeft: Radius.circular(o),
          topRight: Radius.circular(o),
          bottomLeft: Radius.circular(o),
          bottomRight: Radius.circular(t),
        );
      case ChatBubbleGroupSlot.middle:
        return BorderRadius.only(
          topLeft: Radius.circular(o),
          topRight: Radius.circular(t),
          bottomLeft: Radius.circular(o),
          bottomRight: Radius.circular(t),
        );
      case ChatBubbleGroupSlot.last:
        return BorderRadius.only(
          topLeft: Radius.circular(o),
          topRight: Radius.circular(t),
          bottomLeft: Radius.circular(o),
          bottomRight: Radius.circular(t),
        );
    }
  }

  switch (slot) {
    case ChatBubbleGroupSlot.single:
      return BorderRadius.only(
        topLeft: Radius.circular(o),
        topRight: Radius.circular(o),
        bottomLeft: Radius.circular(t),
        bottomRight: Radius.circular(o),
      );
    case ChatBubbleGroupSlot.first:
      return BorderRadius.only(
        topLeft: Radius.circular(o),
        topRight: Radius.circular(o),
        bottomLeft: Radius.circular(t),
        bottomRight: Radius.circular(o),
      );
    case ChatBubbleGroupSlot.middle:
      return BorderRadius.only(
        topLeft: Radius.circular(t),
        topRight: Radius.circular(o),
        bottomLeft: Radius.circular(t),
        bottomRight: Radius.circular(o),
      );
    case ChatBubbleGroupSlot.last:
      return BorderRadius.only(
        topLeft: Radius.circular(t),
        topRight: Radius.circular(o),
        bottomLeft: Radius.circular(t),
        bottomRight: Radius.circular(o),
      );
  }
}

EdgeInsets chatBubbleGroupMargin(ChatBubbleGroupSlot slot) {
  switch (slot) {
    case ChatBubbleGroupSlot.single:
      return const EdgeInsets.only(top: 4, bottom: 4);
    case ChatBubbleGroupSlot.first:
      return const EdgeInsets.only(top: 4, bottom: 1);
    case ChatBubbleGroupSlot.middle:
      return const EdgeInsets.only(top: 1, bottom: 1);
    case ChatBubbleGroupSlot.last:
      return const EdgeInsets.only(top: 1, bottom: 4);
  }
}

bool chatBubbleShowsTimestampMeta(ChatBubbleGroupSlot slot) {
  return slot == ChatBubbleGroupSlot.single ||
      slot == ChatBubbleGroupSlot.last;
}
