class ExcursionMaterial {
  final String id;
  final String title;
  final String text;
  final String? fileName;
  final String? filePath;

  const ExcursionMaterial({
    required this.id,
    required this.title,
    this.text = '',
    this.fileName,
    this.filePath,
  });

  bool get hasFile => filePath != null && filePath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        if (fileName != null) 'fileName': fileName,
        if (filePath != null) 'filePath': filePath,
      };

  factory ExcursionMaterial.fromJson(Map<String, dynamic> json) => ExcursionMaterial(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        fileName: json['fileName'] as String?,
        filePath: json['filePath'] as String?,
      );
}

class ExcursionStop {
  final String zoneId;
  final List<String> speciesIds;
  final String? theoryId;
  final bool done;

  const ExcursionStop({
    required this.zoneId,
    this.speciesIds = const [],
    this.theoryId,
    this.done = false,
  });

  ExcursionStop copyWith({
    String? zoneId,
    List<String>? speciesIds,
    String? theoryId,
    bool clearTheory = false,
    bool? done,
  }) =>
      ExcursionStop(
        zoneId: zoneId ?? this.zoneId,
        speciesIds: speciesIds ?? this.speciesIds,
        theoryId: clearTheory ? null : (theoryId ?? this.theoryId),
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'speciesIds': speciesIds,
        'theoryId': theoryId,
        'done': done,
      };

  factory ExcursionStop.fromJson(Map<String, dynamic> json) => ExcursionStop(
        zoneId: json['zoneId'] as String? ?? '',
        speciesIds: ((json['speciesIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
        theoryId: json['theoryId'] as String?,
        done: json['done'] as bool? ?? false,
      );
}

class Excursion {
  final String id;
  final String title;
  final int durationMinutes;
  final String meetingPoint;
  final String story;
  final String departure;
  final List<String> participants;
  final List<ExcursionStop> stops;
  final List<ExcursionMaterial> materials;

  const Excursion({
    required this.id,
    required this.title,
    this.durationMinutes = 90,
    this.meetingPoint = '',
    this.story = '',
    this.departure = '10:00',
    this.participants = const [],
    this.stops = const [],
    this.materials = const [],
  });

  int get doneCount => stops.where((stop) => stop.done).length;

  Excursion copyWith({
    String? title,
    int? durationMinutes,
    String? meetingPoint,
    String? story,
    String? departure,
    List<String>? participants,
    List<ExcursionStop>? stops,
    List<ExcursionMaterial>? materials,
  }) =>
      Excursion(
        id: id,
        title: title ?? this.title,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        meetingPoint: meetingPoint ?? this.meetingPoint,
        story: story ?? this.story,
        departure: departure ?? this.departure,
        participants: participants ?? this.participants,
        stops: stops ?? this.stops,
        materials: materials ?? this.materials,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'durationMinutes': durationMinutes,
        'meetingPoint': meetingPoint,
        'story': story,
        'departure': departure,
        'participants': participants,
        'stops': stops.map((stop) => stop.toJson()).toList(),
        'materials': materials.map((item) => item.toJson()).toList(),
      };

  factory Excursion.fromJson(Map<String, dynamic> json) => Excursion(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 90,
        meetingPoint: json['meetingPoint'] as String? ?? '',
        story: json['story'] as String? ?? '',
        departure: json['departure'] as String? ?? '10:00',
        participants: ((json['participants'] as List?) ?? const []).map((e) => e.toString()).toList(),
        stops: ((json['stops'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ExcursionStop.fromJson(e.cast<String, dynamic>()))
            .where((stop) => stop.zoneId.isNotEmpty)
            .toList(),
        materials: ((json['materials'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ExcursionMaterial.fromJson(e.cast<String, dynamic>()))
            .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
            .toList(),
      );
}
