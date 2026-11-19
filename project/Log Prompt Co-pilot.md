# Log Pengembangan Game Bersama Copilot

Dokumen ini merangkum permintaan pengembangan yang tercatat dalam sesi 14–19 November 2026, hasilnya, serta perubahan yang dibuat Copilot. Proyek sudah memiliki permainan dan scene Level 1–5; log ini berfokus pada pekerjaan Copilot dalam rangkaian permintaan tersebut, bukan mengklaim seluruh game dibuat Copilot. Aset dan rancangan scene yang sudah dibuat pengguna dicatat sebagai bahan integrasi, bukan sebagai karya yang dibuat Copilot.

## Riwayat permintaan dan hasil

### 1. Gerigi besar bergerak dan menjadi bahaya

**Permintaan yang dirapikan:** Gerakkan animasi gerigi besar ke kiri dan kanan mengikuti jalurnya. Jika gerigi menyentuh player, jalankan mekanisme kematian player.

**Hasil:** Gerigi bergerak berulang di antara dua batas dan memanggil `die()` saat area bahayanya menyentuh player.

**Perubahan:** Menambahkan [Script/large_gear.gd](Script/large_gear.gd) dan menghubungkan script serta area bahayanya di [Scene/Level 5.tscn](Scene/Level%205.tscn).

### 2. Batas gerak gerigi ditentukan dengan koordinat kiri dan kanan

**Permintaan yang dirapikan:** Tampilkan batas posisi kiri dan kanan secara langsung agar jarak gerak mudah disesuaikan.

**Hasil:** Pengaturan gerak memakai `left_limit_x` dan `right_limit_x`, yang dapat diubah dari Inspector. Nilai awal script adalah `-243.76` dan `56.24`; nilai pada node Level 5 dapat diatur tersendiri.

**Perubahan:** Mengganti pengaturan jarak tempuh dengan batas X kiri dan kanan di [Script/large_gear.gd](Script/large_gear.gd).

### 3. Checkpoint menyimpan titik respawn

**Permintaan yang dirapikan:** Setelah player melewati checkpoint, kematian berikutnya harus mengembalikan player ke checkpoint terakhir. Satu level boleh memiliki beberapa checkpoint.

**Hasil:** Posisi player disimpan saat checkpoint aktif dan digunakan kembali setelah animasi kematian selesai. Implementasi awal menggunakan scene checkpoint terpisah.

**Perubahan awal:** Menambahkan [Script/checkpoint.tscn](Script/checkpoint.tscn), [Script/checkpoint.gd](Script/checkpoint.gd), serta fungsi penyimpanan posisi di [Script/player.gd](Script/player.gd).

### 4. Checkpoint disesuaikan dengan AnimatedSprite2D di Level 5

**Permintaan yang dirapikan:** Karena implementasi checkpoint awal dihapus, gunakan kembali AnimatedSprite2D checkpoint yang sudah ada di Level 5, dengan animasi “Sebelum” dan “Sesudah”.

**Hasil:** Script dipasang langsung pada node **Animate Check Point**. Area pemicu mendeteksi player; ketika disentuh, posisi respawn tersimpan dan animasi berubah dari “Sebelum” ke “Sesudah”.

**Perubahan:** Menyesuaikan [Script/checkpoint.gd](Script/checkpoint.gd), [Script/player.gd](Script/player.gd), dan node checkpoint di [Scene/Level 5.tscn](Scene/Level%205.tscn). Implementasi ini menggantikan kebutuhan untuk membuat scene checkpoint terpisah.

### 5. Dukungan beberapa checkpoint dalam satu level

**Permintaan yang dirapikan:** Pastikan beberapa checkpoint dalam satu level dapat digunakan dengan aman.

**Hasil:** Setiap instance memiliki status aktivasi sendiri. Checkpoint yang terakhir disentuh memperbarui titik respawn player.

**Catatan penggunaan:** Duplikat node checkpoint bersama `CheckpointArea` dan `CollisionShape2D`-nya, lalu atur posisinya. Hindari area pemicu yang saling tumpang tindih.

### 6. Platform menghilang dan Enemy Alpha di-reset saat player respawn

**Permintaan yang dirapikan:** Saat player mati dan muncul kembali, pulihkan disappearing platform dan munculkan kembali enemy yang sudah dikalahkan.

**Hasil:** Platform kembali terlihat dan dapat diinjak; enemy kembali ke posisi awal, aktif, dan memainkan animasi idle. Timer dan tween platform yang masih berjalan dibatalkan agar tidak menimbulkan perubahan terlambat.

**Perubahan:** Memperbarui [Script/disappearing_platform.gd](Script/disappearing_platform.gd), [Script/enemy_alpha.gd](Script/enemy_alpha.gd), dan [Script/player.gd](Script/player.gd). Objek yang perlu di-reset masuk ke grup `reset_on_player_respawn`.

### 7. Menu utama dan progres level

**Permintaan yang dirapikan:** Hubungkan empat tombol menu—Play, Levels, Settings, dan Quit—dengan animasi hover/klik. Play membuka level tertinggi yang sudah terbuka; Levels menampilkan panel pilihan Level 1–10 dengan status terkunci, terbuka, atau selesai. Level 6–10 harus tetap terkunci selama levelnya belum tersedia. Settings ditunda sampai panelnya dibuat, sedangkan Quit menutup game.

**Hasil:** Menu utama dijadikan scene awal. Tombol memperoleh animasi hover/klik, panel Levels muncul dengan animasi pop-up, tombol level memakai aset status yang sesuai, Play membuka level tertinggi yang tersedia dan terbuka, serta Quit menutup game. Progres tersimpan di `user://progress.cfg`; menyelesaikan level melalui portal menandai level selesai dan membuka level berikutnya jika scene-nya tersedia.

**Perubahan:** Menambahkan [Script/main_menu.gd](Script/main_menu.gd); memperbarui [Script/game_manager.gd](Script/game_manager.gd), [Script/level_portal.gd](Script/level_portal.gd), [Scene/Main Menu.tscn](Scene/Main%20Menu.tscn), dan [project.godot](project.godot).

**Catatan:** Panel Settings belum dibuat, jadi tombolnya hanya memiliki animasi dan belum membuka pengaturan. Untuk menambahkan level berikutnya, masukkan path scene ke `LEVEL_SCENES` di GameManager dan pastikan scene tersebut tersedia.

### 8. Transisi saat berganti scene

**Permintaan yang dirapikan:** Saat berpindah scene, tirai kiri dan kanan masuk dari luar hingga menutup layar. Setelah scene tujuan dimuat, jalankan animasi transisi, lalu buka tirai ke arah luar.

**Hasil:** Perpindahan melalui GameManager menggunakan pengelola transisi bersama. Tirai layar menutup, animasi dari scene transisi berjalan di atas scene baru, lalu tirai terbuka kembali.

**Perubahan:** Menambahkan [Script/scene_transition.gd](Script/scene_transition.gd), mendaftarkan `SceneTransition` di bagian autoload [project.godot](project.godot), dan merutekan pergantian level melalui pengelola tersebut di [Script/game_manager.gd](Script/game_manager.gd). Scene dan gambar transisi disediakan pengguna.

### 9. Perbaikan error autoload

**Permintaan yang dirapikan:** Cari penyebab banyaknya error setelah integrasi menu dan transisi, lalu perbaiki.

**Hasil:** Ditemukan bahwa bagian `[autoload]` di `project.godot` hilang, sehingga `GameManager` dan `SceneTransition` tidak tersedia sebagai singleton. Kedua autoload didaftarkan kembali.

**Perubahan:** Memperbarui [project.godot](project.godot). Pemeriksaan Problems setelah perbaikan melaporkan tidak ada error.

## Ringkasan kontribusi Copilot

### Script yang dibuat

- [Script/large_gear.gd](Script/large_gear.gd): gerak bolak-balik gerigi, batas kiri/kanan, dan deteksi bahaya.
- [Script/checkpoint.gd](Script/checkpoint.gd): aktivasi checkpoint, penyimpanan posisi respawn, dan pergantian animasi.
- [Script/main_menu.gd](Script/main_menu.gd): tombol menu, animasi interaksi, panel pilihan level, dan pemilihan aset status.
- [Script/scene_transition.gd](Script/scene_transition.gd): tirai penutup/pembuka dan pemutaran scene animasi transisi.

### Script dan scene yang diintegrasikan atau diperbarui

- [Script/player.gd](Script/player.gd): aktivasi checkpoint dan pemulihan objek level setelah respawn.
- [Script/disappearing_platform.gd](Script/disappearing_platform.gd): pemulihan platform dan pembatalan timer/tween yang sudah tidak berlaku.
- [Script/enemy_alpha.gd](Script/enemy_alpha.gd): mempertahankan enemy yang kalah agar dapat dihidupkan kembali.
- [Script/game_manager.gd](Script/game_manager.gd): daftar scene level, pemilihan level, progres tersimpan, status selesai/terbuka, dan integrasi transisi.
- [Script/level_portal.gd](Script/level_portal.gd): pencatatan penyelesaian level dan perpindahan melalui transisi.
- [Scene/Level 5.tscn](Scene/Level%205.tscn): pemasangan script gerigi dan checkpoint serta area pemicunya.
- [Scene/Main Menu.tscn](Scene/Main%20Menu.tscn): pemasangan script pada scene menu yang telah disiapkan pengguna.
- [project.godot](project.godot): scene awal menu dan konfigurasi autoload.

## Validasi dan batas pengujian

Pemeriksaan statis seperti `git diff --check`, keberadaan aset, dan koneksi scene/script dijalankan pada beberapa tahap dan berhasil. Setelah error autoload diperbaiki, panel Problems juga melaporkan tidak ada error.

Game belum dapat dijalankan untuk pengujian langsung karena executable Godot tidak tersedia di lingkungan kerja saat perubahan tersebut dibuat. Karena itu, animasi, input, dan alur permainan tetap perlu dicoba langsung di Godot.