import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/checkin_exercise_widgets.dart';

void main() {
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
        'Keep your elbows tucked and avoid locking your shoulders.',
      ),
      checkinErrosComunsFallback,
    );
    expect(
      checkinErrosComunsBody('Não arqueie a lombar.'),
      'Não arqueie a lombar.',
    );
  });
}
