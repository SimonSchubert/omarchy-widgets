# IMASA

Widget berbahasa Indonesia untuk jam perangkat, kalender Hijriah KHGT, jadwal
shalat Muhammadiyah, dan informasi puasa. Tampilan utama berukuran 6×3 sel;
ketuk untuk membuka jadwal, kalender, lokasi, dan setelan.

## Mulai memakai

1. Buka widget dan pilih tab **Lokasi**.
2. Cari nama kota (minimal tiga karakter) melalui Open-Meteo, atau masukkan
   nama dan koordinat secara manual.
3. Simpan lokasi favorit bila diperlukan. Jadwal yang berhasil diunduh
   otomatis disimpan dalam cache, maksimal 40 entri lokasi/tanggal.
4. Atur pengingat 5, 10, atau 15 menit sebelum shalat, notifikasi waktu tiba,
   dan suara di tab **Setelan**. Pengingat sebelum shalat nonaktif secara
   bawaan; notifikasi waktu tiba aktif setelah jadwal dan zona waktu tersedia.

Kalender dapat ditelusuri per bulan; ketuk tanggal untuk melihat jadwal dan
informasi puasa tanggal tersebut. Jadwal tanggal pilihan diambil terpisah
dan tidak disimpan dalam cache harian. Jika zona lokasi berbeda dari
perangkat, widget menampilkan dua jam.

## Sumber data dan privasi

- Jadwal shalat dan kalender: API KHGT Muhammadiyah
  (`api-khgt.muhammadiyah.or.id`). IMASA adalah widget independen.
- Zona waktu, matahari terbit/terbenam, dan pencarian kota: Open-Meteo
  (`api.open-meteo.com`, `geocoding-api.open-meteo.com`).
- Koordinat dikirim untuk mengambil zona waktu dan jadwal setelah lokasi
  dipilih. Nama kota dikirim saat pencarian online. Tidak menggunakan GPS.
- Preset suara diunduh dari `actions.google.com` ketika diputar. Suara
  sendiri dapat menggunakan URL atau path file yang ditentukan pengguna.
- Lokasi, favorit, cache, dan setelan disimpan di perangkat. Tidak memerlukan
  akun, API key, perintah shell, atau paket Linux tambahan.

## Batasan

Internet diperlukan untuk pencarian dan pengambilan data baru. Cache hanya
digunakan bila lokasi dan tanggal sesuai; cache lama bukan jadwal hari ini.
Notifikasi dapat terlambat saat ponsel tidur dan bukan pengganti alarm sistem.
Suara notifikasi hanya berbunyi saat layar atau aplikasi terbuka.

Memerlukan OWL 11 atau lebih baru. Versi 0.21.0, lisensi MIT.
Pratinjau menampilkan contoh lokasi; instalasi baru meminta pengguna memilih
lokasi sendiri.
