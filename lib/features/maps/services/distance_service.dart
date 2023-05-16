import 'dart:math';


class Haversine {
  double? latitude1;
  double? latitude2;
  double? longitude1;
  double? longitude2;

  Haversine({this.latitude1, this.latitude2, this.longitude1, this.longitude2});

  double distance() {
    latitude1 = latitude1! * (3.14 / 180.0);
    latitude2 = latitude2! * (3.14 / 180.0);
    longitude1 = longitude1! * (3.14 / 180.0);
    longitude2 = longitude2! * (3.14 / 180.0);
    double R = 6371;
    double latitudeDifferece = latitude2! - latitude1!;
    double longitudeDifferece = longitude2! - longitude1!;
    double a = pow(sin((latitudeDifferece / 2)), 2) +
        cos(latitude1!) * cos(latitude2!) * pow(sin(longitudeDifferece / 2), 2);
    double sqrtOfA = sqrt(a);
    double n = 1 - sqrtOfA;
    double sqrtOfA_1 = sqrt(n);
    double c = 2 * atan2(sqrtOfA, sqrtOfA_1);
    double distance = R * c;

    return distance * 1000;
  }
}
