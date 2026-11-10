class MentalHealthQuote {
  const MentalHealthQuote({required this.text, required this.author});

  final String text;
  final String author;
}

class MentalHealthQuotes {
  MentalHealthQuotes._();

  static const all = [
    MentalHealthQuote(
      text:
          "You don't have to control your thoughts. You just have to "
          'stop letting them control you.',
      author: 'Dan Millman',
    ),
    MentalHealthQuote(
      text: 'It is okay to not be okay, as long as you are not giving up.',
      author: 'Karen Salmansohn',
    ),
    MentalHealthQuote(
      text: 'Self-care is how you take your power back.',
      author: 'Lalah Delia',
    ),
    MentalHealthQuote(
      text: 'You are not your illness. You have an individual story to tell.',
      author: 'Julian Seifter',
    ),
    MentalHealthQuote(text: 'Progress, not perfection.', author: 'Anonymous'),
    MentalHealthQuote(
      text:
          'Rest is not idleness, and lying sometimes on the grass under '
          'trees on a summer\'s day is by no means a waste of time.',
      author: 'John Lubbock',
    ),
    MentalHealthQuote(
      text:
          'Your present circumstances don\'t determine where you can go; '
          'they merely determine where you start.',
      author: 'Nido Qubein',
    ),
    MentalHealthQuote(
      text: 'Healing takes time, and asking for help is a courageous step.',
      author: 'Mariska Hargitay',
    ),
    MentalHealthQuote(
      text:
          "You've survived 100% of your worst days. You're doing better "
          'than you think.',
      author: 'Anonymous',
    ),
    MentalHealthQuote(
      text: 'Small steps still move you forward.',
      author: 'Anonymous',
    ),
  ];

  /// Stable for the whole day (not re-randomized on every rebuild) so the
  /// card doesn't flicker to a different quote on every setState elsewhere
  /// on the Dashboard.
  static MentalHealthQuote quoteOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return all[dayOfYear % all.length];
  }
}
