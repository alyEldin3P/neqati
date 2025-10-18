// has name and id
enum Branch {
  glc('GLC ABU RAYA', 1),
  kapci('KAPCI ABU RAYA', 2),
  nippon('Nippon ABU RAYA', 3);

  const Branch(this.name, this.id);

  final String name;
  final int id;
}
