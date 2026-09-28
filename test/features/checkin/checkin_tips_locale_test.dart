import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_exercise_tips.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

void main() {
  final s = SPt();

  test('checkinTextLooksNonPtBr catches English cues and stopwords', () {
    expect(
      checkinTextLooksNonPtBr(
        'Keep your elbows close and avoid locking the shoulder from the top.',
      ),
      isTrue,
    );
    expect(
      checkinTextLooksNonPtBr(
        'Não trave os cotovelos e mantenha o peito aberto.',
      ),
      isFalse,
    );
    expect(checkinTextLooksNonPtBr(''), isFalse);
  });

  test('checkinErrosComunsBody swaps EN copy for PT fallback', () {
    expect(
      checkinErrosComunsBody(
        s,
        'Keep your elbows tucked and avoid locking your shoulders.',
      ),
      'Peça orientação ao personal se tiver dúvida na execução.',
    );
    expect(
      checkinErrosComunsBody(s, 'Não arqueie a lombar.'),
      'Não arqueie a lombar.',
    );
    expect(checkinErrosComunsBody(s, null), '');
  });
}
