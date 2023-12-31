class Time {
  const Time({
    required this.signature,
  });

  final TimeSignatureChoice? signature;
}

sealed class TimeSignatureChoice {}

class TimeSignature implements TimeSignatureChoice {
  const TimeSignature({
    required this.beats,
    required this.beatType,
  });

  final String beats;
  final String beatType;
}
