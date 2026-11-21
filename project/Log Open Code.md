# Log Pengembangan Game Bersama Open Code

Dokumen ini mencatat setiap perubahan yang dibuat Open Code pada proyek ini. Setiap entri diawali dengan permintaan pengguna yang dirapikan bahasanya, disusul dengan hasil dan perubahan yang dilakukan. Format ini mengikuti konvensi pada [Log Prompt Co-pilot.md](Log%20Prompt%20Co-pilot.md).

---

### 1. Audit menyeluruh dan penulisan ulang README.md

**Permintaan yang dirapikan:** Lakukan audit menyeluruh terhadap proyek Godot, mencakup `project.godot`, seluruh berkas `.tscn` di `Scene/`, seluruh skrip `.gd` di `Script/`, serta seluruh isi `Asset/`. Jelaskan secara ringkas gameplay, kontrol, mekanik, dan isi tiap scene/level yang benar-benar terpasang; bandingkan temuan aktual dengan isi `README.md` yang lama; lalu tulis ulang `README.md` sebagai dokumentasi GDD yang 100% sesuai fakta proyek. Hapus atau revisi fitur, simbol, musuh, dan level yang ternyata tidak ada; tambahkan mekanik, kontrol, node, dan level yang ternyata sudah dibuat; pastikan struktur direktori serta daftar skrip identik dengan susunan asli; dan jangan mengarang fitur yang tidak ada di kode.

**Hasil:** Terverifikasi bahwa tidak ada InputMap, hanya tombol `A`/`←` dan `D`/`→` yang berfungsi dan keduanya sekaligus memicu lompat; `GameManager` mendeklarasikan 10 level sementara yang tersedia hanya 5; tombol Settings belum berfungsi; tidak ada berkas audio; dan `character_scene.tscn` serta `moving_platform.tscn` tidak pernah di-instance. `README.md` kini mendokumentasikan kondisi proyek yang sebenarnya.

**Perubahan:** Menulis ulang [README.md](README.md) menjadi 8 bagian (identitas proyek, gameplay, kontrol, daftar 15 skrip, entitas/simbol, isi 6 scene, struktur direktori, serta koreksi dan anomali teknis) dan memverifikasi ulang isinya terhadap berkas proyek.

---

### 2. Pencatatan perubahan dan penyesuaian dokumentasi

**Permintaan yang dirapikan:** Mulai sekarang, setiap perubahan yang dilakukan hendaknya dicatat di `Log Open Code.md`. Format setiap entri: terlebih dahulu nyatakan keinginan pengguna dengan bahasa yang lebih rapi dan formal, baru kemudian catat tindakan yang dilakukan. Selain itu, `README.md` harus tetap diperbarui apabila isinya menjadi tidak sesuai dengan kondisi proyek terbaru.

**Hasil:** Tersedia berkas log dengan format yang sejajar dengan log Copilot, dan daftar berkas di root `README.md` menjadi akurat kembali setelah munculnya berkas-berkas baru di proyek.

**Perubahan:** Membuat [Log Open Code.md](Log%20Open%20Code.md) dengan dua entri (audit/README dan pencatatan ini); memperbarui [README.md](README.md) dengan menambahkan `GD.md`, `Log Open Code.md`, dan `Log Prompt Co-pilot.md` ke pohon struktur direktori serta merapikan nama berkas log pada bagian identitas proyek.

**Catatan:** `GD.md` berisi rancangan naratif dengan beberapa klaim yang belum sesuai kode (misalnya karakter $\pi$, simbol $+$ dan $\sqrt{\phantom{x}}$, serta Ω sebagai hazard). Berkas tersebut tidak diubah karena permintaan hanya mencakup `README.md`.

---

### 3. Sistem round pada panel level menu utama

**Permintaan yang dirapikan:** Sesuaikan menu utama dengan perubahan scene yang telah dibuat pengguna. Panel level kini terdiri dari Round 1, Round 2, dan Round 3 yang masing-masing memuat enam level. Round berikutnya hanya boleh dibuka setelah keenam level pada round sebelumnya selesai; apabila level keenam belum selesai, tombol Next harus dinonaktifkan. Pada Round 1, tombol Back disembunyikan sehingga yang tampil hanya tombol Next dan teks round. Perpindahan antar-round dianimasikan dengan gaya slide. Tombol Next dan Back diberi efek pop-up saat di-hover maupun saat diklik. Teks round ditempatkan tepat di tengah dan dibuat mudah terlihat oleh pemain, misalnya melalui animasi atau perubahan warna.

**Hasil:** Panel `Panel panel` kini berfungsi menggantikan referensi lama `Levels Panel` yang sudah tidak ada. Seluruh 18 tombol level terhubung; Next hanya aktif bila keenam level di round aktif berstatus selesai dan masih ada round berikutnya; Back otomatis tersembunyi di Round 1. Perpindahan round memakai tween slide berlawanan arah, tombol Next/Back memakai animasi pop-up, dan teks "ROUND 1/2/3" tampil di tengah dengan warna biru neon, animasi muncul, dan denyut halus. Teks tidak menghalangi klik level karena `mouse_filter = IGNORE`.

**Perubahan:** Menulis ulang [Script/main_menu.gd](Script/main_menu.gd) untuk logika 3 round × 6 level, slide, pop-up, dan banner round; memperluas daftar level di [Script/game_manager.gd](Script/game_manager.gd) menjadi 18 entri agar progres 3 round dapat disimpan; menyesuaikan [Scene/Main Menu.tscn](Scene/Main%20Menu.tscn) pada posisi/warna/`mouse_filter` `Round Text`, pengaturan `TextEdit`, dan `clip_contents` panel; memperbarui [README.md](README.md) agar sesuai dengan struktur menu terbaru.

**Batasan:** Saat ini hanya `Level 1.tscn`–`Level 5.tscn` yang tersedia dan tekstur status level hanya hingga nomor 10, sehingga level 6–18 belum dapat dimainkan dan tombol Next akan tetap nonaktif secara praktis sampai scene/tekstur tersebut ditambahkan. Tombol level 11–18 mempertahankan tekstur sementara yang sudah dipasang di scene. Validasi dilakukan secara statis karena executable Godot tidak tersedia di lingkungan ini.

---

### 4. Perapian teks round dan umpan balik tombol navigasi

**Permintaan yang dirapikan:** Yang dimaksud sebelumnya adalah node `TextEdit` di dalam `Round Text`: teksnya yang harus berada tepat di tengah, bukan objek/node-nya. Teks juga perlu efek animasi supaya mudah terlihat pemain. Tombol Next dan Back harus tetap mendapat efek pop-up saat di-hover walaupun dalam keadaan dinonaktifkan, dan tetap memiliki efek saat diklik. Selain itu, perlu perbedaan warna atau penanda lain antara kondisi enabled dan disabled.

**Hasil:** Teks "ROUND 1/2/3" kini benar-benar terpusat di dalam kotaknya karena node turunannya diganti dari `TextEdit` menjadi `Label` dengan `horizontal_alignment` dan `vertical_alignment` bernilai center; `TextEdit` tidak menyediakan properti perataan teks di Godot 4. Label diberi font lebih besar dan animasi denyut berkelanjutan (skala 1,00–1,06 disertai pergantian warna), sementara bannernya tetap memiliki animasi muncul dan meluncur dari tengah. Tombol Next/Back tetap pop-up saat hover meskipun disabled, pop-up saat diklik saat enabled, serta berubah warna dari putih cerah (enabled) menjadi abu kebiruan redup (disabled) dengan transisi 0,15 dtk.

**Perubahan:** Memperbarui [Scene/Main Menu.tscn](Scene/Main%20Menu.tscn) (node `Round Label` bertipe `Label`, alignment tengah, ukuran font 42, pivot untuk denyut) dan [Script/main_menu.gd](Script/main_menu.gd) (tween denyut teks, pengecualian hover saat disabled khusus Next/Back, tween warna status navigasi); menyelaraskan [README.md](README.md) dengan perilaku terbaru.

**Catatan:** Karena tombol disabled secara bawaan tidak memancarkan sinyal `pressed` di Godot, efek klik hanya muncul saat tombol enabled; efek hover tetap muncul pada kedua kondisi.

---

### 5. Panel Settings dan sistem BGM global

**Permintaan yang dirapikan:** Pertama, susun panel Settings mengikuti contoh yang tersedia di folder Settings: setiap slider harus memberikan efek pop-up saat hendak diubah, tombol juga ber-pop-up saat diklik, kemunculan dan keluarnya panel harus beranimasi pop-up, dan tombol Reset Data harus mengembalikan progres level. Kedua, siapkan integrasi untuk musik yang akan dipasang; SFX belum tersedia sehingga ditunda. Ketiga, periksa struktur proyek (konfigurasi, scene, skrip, dan folder audio) lalu terapkan sistem manajemen BGM melalui autoload global: BGM Main Menu dan BGM Gameplay terpisah, keduanya seamless loop, fade-in 0,8–1,0 detik dari senyap saat awal scene, fade-out cepat 0,25–0,35 detik lalu `stop()` ketika perpindahan scene dimulai, hening total selama transisi, dan BGM scene tujuan baru fade-in setelah transisi selesai membuka. Player BGM harus masuk ke bus Audio `Music` agar sinkron dengan slider MUSIC di Settings.

**Hasil:** Ditemukan dua berkas BGM MP3 di `Audio/BGM/`. `AudioManager` kini mengelola bus `Music` (dibuat saat runtime bila belum ada), memilih BGM otomatis berdasarkan scene aktif, mencegah restart saat panel dibuka/ditutup, memutar loop, melakukan fade-in 0,9 dtk dari −40 dB, serta fade-out 0,3 dtk dan `stop()` sebelum transisi berjalan. Tidak ada BGM yang diputar selama transisi; BGM tujuan dimulai setelah tirai terbuka. Panel Settings kini memuat slider MUSIC/SFX bergaya contoh, efek pop-up pada slider dan tombol, animasi panel, Reset progres yang berfungsi, serta penyimpanan volume di `user://settings.cfg`.

**Perubahan:** Menambah [Script/audio_manager.gd](Script/audio_manager.gd) dan mendaftarkannya di [project.godot](project.godot); mengubah [Script/scene_transition.gd](Script/scene_transition.gd) untuk fade-out/hening/fade-in; menambah `reset_progress()` di [Script/game_manager.gd](Script/game_manager.gd); menambah node slider pada [Scene/Main Menu.tscn](Scene/Main%20Menu.tscn) dan logika Settings di [Script/main_menu.gd](Script/main_menu.gd); mengaktifkan `loop=true` pada dua berkas `.import` BGM; memperbarui [README.md](README.md).

**Catatan:** SFX memang belum ada berkas audio, jadi slider SFX hanya menyimpan nilai untuk integrasi berikutnya. Bus `Music` dibuat melalui kode karena proyek tidak memiliki berkas `default_bus_layout.tres`. Selama pekerjaan ini muncul `Scene/Level 6.tscn` (susunan sama dengan Level 5), sehingga angka jumlah scene di `README.md` diperbarui dari 5 menjadi 6. Verifikasi dilakukan statis karena executable Godot tidak tersedia di lingkungan ini.

---

### 6. Penyesuaian skrip untuk slider HSlider hasil penataan ulang pengguna

**Permintaan yang dirapikan:** Pengguna sudah menata ulang layout panel Settings dan mengganti slider yang sebelumnya berupa `TextureProgressBar` menjadi `HSlider`. Sesuaikan kembali skrip bila masih ada yang tidak cocok dengan struktur scene terbaru.

**Hasil:** Ditemukan beberapa ketidaksesuaian: jenis node slider berubah menjadi `HSlider`, nama nodenya menjadi `Music Slidder` dan `SFX Slidder`, label nilai kini menjadi child masing-masing slider, tombol Reset/Close dipindahkan menjadi anak langsung `Settings Panel`, panel Settings tidak lagi memiliki `visible = false`, dan kedua slider memiliki skala bawaan 0,75 yang akan ditimpa animasi pop-up lama. Semua sudah diperbaiki sehingga jalur node, tipe, rentang nilai, dan animasi sesuai scene.

**Perubahan:** Memperbarui [Script/main_menu.gd](Script/main_menu.gd) (jalur `@onready`, tipe `HSlider`, skala dasar untuk tween pop-up, dan pengaman visibilitas panel) serta [Scene/Main Menu.tscn](Scene/Main%20Menu.tscn) (`visible = false` pada panel dan rentang 0–100 dengan nilai awal pada kedua slider); menyelaraskan [README.md](README.md).

**Catatan:** Ejaan `Music Slidder`/`SFX Slidder` mengikuti nama node di scene agar jalur tetap cocok. Verifikasi kembali bersifat statis karena executable Godot tidak tersedia.

---

### 7. Partikel slash lompat pada pemain

**Permintaan yang dirapikan:** Buat efek partikel dari aset slash yang baru ditambahkan, letakkan tepat di tengah bawah karakter pemain, dan pancarkan saat pemain melakukan lompat. Efeknya harus terasa elastis: saat pemain bergerak ke kiri, slash meliuk ke kanan; saat bergerak ke kanan, slash meliuk ke kiri.

**Hasil:** `player.gd` kini membuat node `CPUParticles2D` bernama `JumpSlashParticles` sebagai anak pemain pada posisi `(0, slash_offset_y)`, memakai tekstur `Efek partikel slash lompat.png`. Emisi terjadi sekali per lompat (juga double jump dan pantulan) dengan `one_shot = true`. Arah emisi dibalik dari arah gerak dan `tangential_accel` diberi tanda berlawanan, sehingga slash membengkok ke sisi lawan gerak; `local_coords = false` membuat partikel tertinggal di dunia saat pemain melaju, memberi kesan cambuk elastis. Seluruh parameter penting diekspos agar bisa diatur di Inspector.

**Perubahan:** Memperbarui [Script/player.gd](Script/player.gd) (ekspor parameter, pembuatan emitter, dan pemicu emisi di `_jump`, `bounce_from_phi`, `bounce_from_enemy`) serta [README.md](README.md) (daftar skrip, tabel entitas, dan daftar aset).

**Catatan:** Emitter dibuat secara prosedural agar otomatis terdapat di keenam scene level yang memakai `player.gd` secara inline, tanpa harus menyunting enam `.tscn`. Posisi `slash_offset_y = 28.0` dan skala partikel bisa disesuaikan di Inspector bila dirasa perlu. Validasi statis; Godot tidak tersedia di lingkungan ini.

---

### 8. Penyesuaian jumlah partikel dan perbaikan error debugger

**Permintaan yang dirapikan:** Ubah efek slash agar hanya mengeluarkan satu partikel per lompat, tetapi bertahan lebih lama. Selain itu, periksa error yang muncul di debugger Godot dan perbaiki.

**Hasil:** Log runtime Godot (`app_userdata/Project Generative AI/logs/godot.log`) menunjukkan error: `scene_changed` memanggil callable dengan 0 argumen, sementara `AudioManager::_on_scene_changed` didefinisikan dengan 1 parameter. Handler diubah menerima argumen opsional (`_scene_root: Node = null`) sehingga kompatibel dengan kedua bentuk sinyal. Partikel diatur menjadi `slash_amount = 1` dan `slash_lifetime = 0,9` dtk; kecepatan diturunkan dan skala sedikit diperbesar agar satu slash tetap terlihat jelas.

**Perubahan:** Memperbarui [Script/player.gd](Script/player.gd) dan [Script/audio_manager.gd](Script/audio_manager.gd); menyelaraskan [README.md](README.md).

**Catatan:** Log juga memuat warning lama **"Concave polygon is assigned to ConvexPolygonShape2D"** dari data tabrakan di scene level (misalnya `ConvexPolygonShape2D_8f85w` di `Level 2.tscn`). Ini warning bawaan aset level, bukan error dari perubahan ini, dan sengaja tidak diubah agar geometri tabrakan tidak bergeser.

---

### 9. Partikel slash kecil-kecil dan berjumlah banyak

**Permintaan yang dirapikan:** Kembalikan efek slash menjadi banyak partikel dengan durasi singkat, tetapi perkecil ukuran pikselnya sangat kecil sehingga kesannya seperti banyak slash kecil-kecil yang keluar sekaligus.

**Hasil:** Emisi kembali menjadi 14 partikel per lompat dengan lifetime 0,3 dtk. Skala partikel diperkecil menjadi 0,03–0,065 dari tekstur sumber, spread diperlebar menjadi 42°, kecepatan 120–230, dan gravitasi 320 agar slash kecil menyebar cepat lalu segera hilang.

**Perubahan:** Memperbarui [Script/player.gd](Script/player.gd) dan [README.md](README.md).

**Catatan:** Nilai tetap diekspos di Inspector (`slash_amount`, `slash_lifetime`, `slash_scale_min/max`, `slash_speed_min/max`, `slash_curl`) sehingga bisa disetel lagi tanpa mengubah kode.

---

### 10. Sistem pause untuk semua level

**Permintaan yang dirapikan:** Pasang scene pause buatan pengguna (pause button, Pause Panel, dan Settings Panel) ke seluruh scene level. Tombol pause perlu efek pop-up saat hover maupun klik. Saat ditekan, Pause Panel tampil dengan urutan animasi: `self_modulate` dari 0 ke nilai semula dengan cepat, BG dan Akar jatuh dari atas bersamaan lalu pop dan mengecil sambil turun sedikit, kemudian teks dan tombol-tombol (Restart, Level, Settings, Resume) muncul pop satu per satu. Setiap tombol juga ber-pop saat hover/klik. Resume melanjutkan game dan menutup panel dengan `self_modulate` ke 0 disertai pop. Restart memakai transisi lalu memuat ulang level yang sama. Level berpindah ke menu dengan panel Level terbuka memakai transisi. Settings memakai perlakuan sama seperti di menu, hanya saja Reset Progres di pause melakukan reset lalu transisi ke menu.

**Hasil:** `Script/pause.gd` dibuat dan dipasang pada root `Script/pause.tscn`; scene tersebut di-instance sebagai node `Pause` di keenam scene level. Node pause ber-`process_mode = ALWAYS` sehingga tetap bekerja saat game di-pause, dengan tween yang juga berjalan saat paused. Seluruh alur tombol dan animasi sesuai urutan yang diminta sudah terpasang, termasuk penanda `GameManager.open_levels_panel_on_menu` agar menu membuka panel Level setelah transisi dari tombol Level.

**Perubahan:** Menambah [Script/pause.gd](Script/pause.gd); memperbarui [Script/pause.tscn](Script/pause.tscn), keenam file `Scene/Level *.tscn`, [Script/game_manager.gd](Script/game_manager.gd), [Script/main_menu.gd](Script/main_menu.gd), dan [README.md](README.md).

**Catatan:** Reset Progres di pause sengaja tidak mengembalikan slider volume — hanya progres level yang dihapus, sesuai permintaan. Verifikasi statis; jalankan di Godot untuk memastikan urutan animasi terasa pas.

---

### 11. Pause mengikuti kamera pemain

**Permintaan yang dirapikan:** Buat agar UI pause selalu menempel pada kamera pemain, sehingga tidak ikut bergeser atau berubah saat `Camera2D` level mengikuti karakter.

**Hasil:** Instance `pause.tscn` pada keenam level kini berada di dalam `CanvasLayer` bernama `"Pause Layer"` (`layer = 90`, `process_mode = ALWAYS`). `CanvasLayer` menggambar anak-anaknya dalam ruang layar, bukan ruang dunia kamera, jadi tombol pause dan panel pause tetap di posisi yang sama walaupun kamera bergerak atau zoom. Layer 90 dipilih agar tirai transisi (layer 100) tetap berada di atasnya.

**Perubahan:** Memperbarui keenam file `Scene/Level *.tscn`, [README.md](README.md), dan entri log ini.

**Catatan:** Tidak ada perubahan pada `pause.gd` atau struktur internal `pause.tscn`; hanya induk instance di scene level yang diubah.

---

### 12. UFO muncul setelah transisi selesai

**Permintaan yang dirapikan:** Ubah timing kemunculan UFO agar baru tampil ketika transisi antar-scene selesai, bukan saat scene level masih dimuat di balik tirai.

**Hasil:** `player.gd` menyembunyikan UFO di `_ready()` dan menunda `_play_spawn_intro()` sampai `SceneTransition.transitioning` bernilai `false` (yaitu setelah animasi transisi dan tirai selesai membuka). `play_arrival()` kemudian menampilkan UFO kembali. Saat level dijalankan langsung tanpa transisi, intro tetap berjalan normal tanpa jeda.

**Perubahan:** Memperbarui [Script/player.gd](Script/player.gd) (tipe `ufo` menjadi `Sprite2D`, `ufo.visible = false` saat `_ready`, dan penunggu transisi di `_play_spawn_intro`) serta [README.md](README.md).

**Catatan:** Tidak mengubah `ufo_animation.gd`; hanya urutan pemanggilannya yang ditunda. Parameter partikel slash milik pengguna tidak disentuh.

---

### 13. Penambahan seluruh SFX

**Permintaan yang dirapikan:** Tambahkan efek suara untuk 13 kondisi: napas idle setelah 1 detik yang berulang dengan jeda 1 detik, lompat, double jump, mendarat, klik tombol, hover tombol, checkpoint, mati karena jatuh, mati karena terkena pisau/gergaji, mati karena musuh, masuk portal, menginjak musuh, spawn pemain (dari UFO maupun setelah mati), dan suara membuka panel UI.

**Hasil:** Terdapat 14 file MP3 di `Audio/SFX/`. `AudioManager` kini membuat bus `SFX`, memuat seluruh berkas sekali, dan menyediakan 12 `AudioStreamPlayer` bergilir sehingga beberapa SFX bisa berbunyi bersamaan; slider SFX kini benar-benar mengatur volume bus tersebut. Napas idle mulai setelah 1 detik diam lalu diulang 1 detik setelah durasi suara berakhir. Kematian dibedakan lewat argumen `die(reason)` (`fall`, `blade`, `enemy`) yang dipanggil dari pemain, gergaji, dan musuh.

**Perubahan:** Memperbarui [Script/audio_manager.gd](Script/audio_manager.gd), [Script/player.gd](Script/player.gd), [Script/enemy_alpha.gd](Script/enemy_alpha.gd), [Script/rotating_saw.gd](Script/rotating_saw.gd), [Script/multi_rotating_saw.gd](Script/multi_rotating_saw.gd), [Script/large_gear.gd](Script/large_gear.gd), [Script/checkpoint.gd](Script/checkpoint.gd), [Script/level_portal.gd](Script/level_portal.gd), [Script/main_menu.gd](Script/main_menu.gd), [Script/pause.gd](Script/pause.gd), dan [README.md](README.md).

**Catatan:** `AudioManager` ber-`process_mode = ALWAYS` supaya SFX tombol panel pause terdengar saat game di-pause. Perubahan animasi hover/click yang dibuat pengguna tetap dipertahankan; hanya panggilan SFX yang disisipkan. Verifikasi statis; jalankan di Godot untuk mendengar hasilnya.

---

### 14. Perbaikan error inferensi tipe SFX

**Permintaan yang dirapikan:** Pengguna menemukan error saat menjalankan proyek: `Error at (83, 21): Cannot infer the type of "path" variable because the value doesn't have a set type.` Perbaiki agar proyek bisa dijalankan.

**Hasil:** Error berada di `AudioManager._load_sfx()`: `SFX_KEYS[key]` adalah `Variant` karena hasil lookup Dictionary, sehingga ekspresi `SFX_DIRECTORY + SFX_KEYS[key]` tidak memiliki tipe yang dapat disimpulkan untuk `:=`. Variabel diubah menjadi `var path: String = SFX_DIRECTORY + str(SFX_KEYS[key])`. Pemeriksaan seluruh skrip menunjukkan tidak ada pola serupa lainnya (dua kecocokan `:= ... [indeks]` lain memakai array bertipe, sehingga aman).

**Perubahan:** Memperbarui [Script/audio_manager.gd](Script/audio_manager.gd).

**Catatan:** Ini error parse/compile, jadi tidak muncul di log runtime Godot. Silakan jalankan lagi untuk memastikan error hilang.

---

### 15. SFX UFO datang

**Permintaan yang dirapikan:** Tambahkan efek suara khusus ketika UFO datang, yaitu saat animasi kedatangan UFO diputar pada proses spawn pemain.

**Hasil:** File `SFX UFO Datang.mp3` sudah tersedia di `Audio/SFX/`. `AudioManager` mendaftarkannya dengan key `ufo_arrival`, dan `play_arrival()` pada `ufo_animation.gd` memicunya tepat saat animasi dimulai (setelah transisi selesai, seiring penundaan spawn yang sudah diterapkan sebelumnya). Total SFX kini 15 file.

**Perubahan:** Memperbarui [Script/audio_manager.gd](Script/audio_manager.gd), [Script/ufo_animation.gd](Script/ufo_animation.gd), dan [README.md](README.md).

**Catatan:** SFX diputar lewat bus `SFX`, sehingga mengikuti slider SFX di panel Settings. Tidak ada perubahan pada timing animasi UFO.

---

### 16. SFX transisi antar scene

**Permintaan yang dirapikan:** Tambahkan suara transisi yang diputar setiap kali perpindahan antar-scene terjadi.

**Hasil:** File `Transition SFX.mp3` terdaftar dengan key `transition` di `AudioManager` dan dipicu di awal `SceneTransition.change_scene()`, tepat sebelum BGM fade-out dan tirai mulai menutup. Karena memakai bus `SFX`, suara ini tidak ikut teredam oleh fade-out BGM dan tetap mengikuti slider SFX. Total SFX kini 16 file.

**Perubahan:** Memperbarui [Script/audio_manager.gd](Script/audio_manager.gd), [Script/scene_transition.gd](Script/scene_transition.gd), dan [README.md](README.md).

**Catatan:** SFX berbunyi sekali per perpindahan scene, termasuk Restart, Level, Reset Progres dari pause, dan portal finish. Tidak mengubah urutan animasi transisi.
