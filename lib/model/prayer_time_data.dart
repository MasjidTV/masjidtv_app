class PrayerTimeData {
  String? zone;
  int? year;
  String? month;
  String? lastUpdated;
  List<Prayers>? prayers;

  PrayerTimeData(
      {this.zone, this.year, this.month, this.lastUpdated, this.prayers});

  PrayerTimeData.fromJson(Map<String, dynamic> json) {
    zone = json['zone'];
    year = json['year'];
    month = json['month'];
    lastUpdated = json['last_updated'];
    if (json['prayers'] != null) {
      prayers = <Prayers>[];
      json['prayers'].forEach((v) {
        prayers!.add(Prayers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['zone'] = zone;
    data['year'] = year;
    data['month'] = month;
    data['last_updated'] = lastUpdated;
    if (prayers != null) {
      data['prayers'] = prayers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Prayers {
  String? hijri;
  int? day;
  DateTime? maghrib;
  DateTime? asr;
  DateTime? syuruk;
  DateTime? isha;
  DateTime? dhuhr;
  DateTime? fajr;

  Prayers(
      {this.hijri,
      this.maghrib,
      this.day,
      this.asr,
      this.syuruk,
      this.isha,
      this.dhuhr,
      this.fajr});

  Prayers.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    hijri = json['hijri'];
    fajr = DateTime.fromMillisecondsSinceEpoch(json['fajr'] * 1000);
    syuruk = DateTime.fromMillisecondsSinceEpoch(json['syuruk'] * 1000);
    dhuhr = DateTime.fromMillisecondsSinceEpoch(json['dhuhr'] * 1000);
    asr = DateTime.fromMillisecondsSinceEpoch(json['asr'] * 1000);
    maghrib = DateTime.fromMillisecondsSinceEpoch(json['maghrib'] * 1000);
    isha = DateTime.fromMillisecondsSinceEpoch(json['isha'] * 1000);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hijri'] = hijri;
    data['maghrib'] = maghrib;
    data['day'] = day;
    data['asr'] = asr;
    data['syuruk'] = syuruk;
    data['isha'] = isha;
    data['dhuhr'] = dhuhr;
    data['fajr'] = fajr;
    return data;
  }
}
