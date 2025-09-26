// has name and id
enum Branch {
  riyadh('Cairo', 1),
  jeddah('Alex', 2);

  const Branch(this.name, this.id);

  final String name;
  final int id;
}
