const leadOrigemValues = [
  'Instagram',
  'Indicação',
  'WhatsApp',
  'Google',
  'Outro',
];

String leadOrigemLabel(String? origem) {
  final value = origem?.trim();
  if (value == null || value.isEmpty) return 'Não informada';
  return value;
}

String leadNovoHubSubtitle() => 'Cadastre um prospect no CRM';
