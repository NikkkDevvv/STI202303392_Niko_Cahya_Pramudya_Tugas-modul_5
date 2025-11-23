# Event Kampus Locator

Aplikasi pencari lokasi event kampus berbasis Flutter menggunakan OpenStreetMap.

## Fitur Utama
1. **Cek Lokasi**: Mengambil koordinat (Latitude/Longitude) dan Alamat pengguna.
2. **Daftar Event**: Menampilkan event kampus terdekat beserta jaraknya (meter).
3. **Peta**: Integrasi OpenStreetMap untuk visualisasi lokasi.
4. **Toggle Akurasi**: Pilihan mode lokasi High/Low.

## Kebijakan Privasi & Izin Lokasi
Aplikasi ini membutuhkan izin `ACCESS_FINE_LOCATION` untuk fitur navigasi yang presisi. Data lokasi hanya digunakan secara lokal di perangkat untuk menghitung jarak ke event dan tidak dikirim ke server eksternal.

## Dampak Baterai (Battery Impact)
Aplikasi menyediakan fitur toggle akurasi:
* **High Accuracy (GPS):** Menggunakan GPS satelit. Memberikan posisi sangat akurat tetapi **mengkonsumsi baterai lebih tinggi** karena sensor GPS aktif terus menerus.
* **Low Accuracy (Network):** Menggunakan Wifi/Cell Tower. Lebih **hemat baterai**, namun akurasi posisi lebih rendah (perkiraan).
Disarankan menggunakan mode Low jika hanya ingin melihat daftar event secara umum.

## Cara Menjalankan (Run)
1. `flutter pub get`
2. `flutter run` (Pastikan di perangkat fisik untuk hasil GPS terbaik).
