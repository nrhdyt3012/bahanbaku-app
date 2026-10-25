// Alamat API. Bisa diganti tanpa edit kode:
//   flutter run --dart-define=API_URL=http://192.168.1.5:3000/api
// Default 10.0.2.2 = alamat laptop dilihat dari emulator Android.
// Untuk Chrome/Windows desktop pakai http://localhost:3000/api
const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);
