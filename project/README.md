# Symboled — Game Design Document (Dokumentasi Aktual Proyek)

> Dokumen ini disusun **murni dari isi proyek Godot yang ada**: `project.godot`, seluruh `Scene/*.tscn`, seluruh `Script/*.gd` + `Script/*.tscn`, dan seluruh isi `Asset/`. Fitur yang belum ada di kode/scene tidak dicantumkan sebagai fitur jadi.

---

## 1. Identitas & Konfigurasi Proyek

| Item | Nilai aktual (dari `project.godot`) |
| :--- | :--- |
| `config/name` | `"Project Generative AI"` (nama judul visual/aset memakai "SYMBOLED") |
| Versi/fitur | Godot `4.7`, `Forward Plus` |
| Main scene | `res://Scene/Main Menu.tscn` |
| Resolusi | Viewport 1920×1080, override jendela 1920×1080, stretch `canvas_items` |
| Icon | `res://icon.svg` |
| Autoload | `GameManager` → `res://Script/game_manager.gd`; `SceneTransition` → `res://Script/scene_transition.gd`; `AudioManager` → `res://Script/audio_manager.gd` |
| Physics | `3d/physics_engine="Jolt Physics"` (pengaturan 3D; proyek ini sepenuhnya 2D, jadi tidak terpakai) |
| Rendering | `rendering_device/driver.windows="d3d12"` |
| Input | **Tidak ada bagian `[input]` / InputMap sama sekali** |

File pendukung: `.editorconfig` (`charset = utf-8`), `.gitattributes` (`* text=auto eol=lf`), `.gitignore` (mengabaikan `.godot/` dan `/android/`). Catatan setiap perubahan proyek disimpan di `Log Open Code.md`.

---

## 2. Gameplay yang Benar-benar Terpasang

Game platformer 2D minimalis bergaya geometris. Pemain mengendalikan karakter **Φ (Phi)** melintasi platform dari kiri ke kanan, menghindari gergaji berputar, musuh patroli, dan platform yang hilang, lalu masuk ke portal **θ (Theta)** di ujung level. Tidak ada sistem pertarungan: musuh hanya bisa diinjak untuk dibunuh, bukan diserang.

Loop aktual:

1. **Spawn** — setelah transisi antar-scene selesai (tirai terbuka), UFO Ω baru muncul dan turun, karakter Φ lalu tampil dengan animasi *squash & stretch*, melayang, dan UFO pergi. UFO disembunyikan sampai saat itu, sehingga tidak terlihat saat layar masih tertutup. Selama intro ini input tidak diproses.
2. **Navigasi** — setiap penekanan tombol arah sekaligus menggerakkan dan **melompat** (lihat §3). Tersedia **double jump**.
3. **Checkpoint λ** — menyentuh checkpoint menyimpan posisi **pemain saat itu** sebagai titik respawn dan mengubah animasi `Sebelum` → `Sesudah` (sekali pakai per checkpoint).
4. **Kematian & respawn** — jatuh di bawah `y = 1000` atau menyentuh hazard/musuh memicu animasi `Death`; setelah selesai, pemain kembali ke posisi spawn. Musuh dan platform yang hilang ikut direset lewat grup `reset_on_player_respawn`.
5. **Selesai level** — portal θ menandai level selesai, menyimpan progres, lalu (jika ada level berikutnya) menyedot pemain selama 1,5 detik dan memicu transisi.

**Tidak ada** layar ending setelah Level 5: `GameManager.has_next_level()` bernilai false sehingga portal hanya menandai selesai tanpa transisi.

> Koreksi terhadap README lama: tidak ada tombol lompat tersendiri, tidak ada animasi `Run`, tidak ada *coyote time*, tidak ada *variable jump height*, dan UFO **bukan** hazard melainkan efek visual spawn.

---

## 3. Kontrol (Fakta Kode)

Sumber: `Script/player.gd` fungsi `_unhandled_input()` (baris 33–49) dan `_jump()` (baris 131–144).

| Aksi | Tombol yang benar-benar berfungsi |
| :--- | :--- |
| Gerak + lompat ke kiri | `A` atau `Left Arrow` (`KEY_A`, `KEY_LEFT`) |
| Gerak + lompat ke kanan | `D` atau `Right Arrow` (`KEY_D`, `KEY_RIGHT`) |

Aturan penting:

- Input dibaca sebagai `InputEventKey` mentah; hanya event *key-down* tanpa `echo` yang diproses.
- **Space, W, dan Up Arrow tidak melakukan apa pun** — tidak ada kode tombol lompat.
- Satu penekanan arah = horizontal `250 px/s` **dan** impulse vertikal pertama `-405`; penekanan kedua = double jump `-405`. Setelah 2 lompatan, penekanan berikutnya hanya mengubah arah horizontal.
- `velocity.x` bertahan sampai frame pertama setelah mendarat (saat itu dinolkan); tidak ada akselerasi/friksi/air-control.
- Gravitasi `1100`; jatuh di bawah `fall_death_y = 1000` = mati.
- Tidak ada InputMap/action name; tidak ada dukungan gamepad.

Parameter `player.gd` (default, tidak dioverride di scene level mana pun): `horizontal_speed = 250.0`, `jump_velocity = -405.0`, `double_jump_velocity = -405.0`, `gravity = 1100.0`, `fall_death_y = 1000.0`.

---

## 4. Sistem & Skrip

### 4.1 Daftar lengkap skrip di `Script/` (17 file `.gd`)

| File | Extends | Peran aktual |
| :--- | :--- | :--- |
| `player.gd` | `CharacterBody2D` | Input arah/lompat, double jump, gravitasi, animasi Idle/Jump/Death, spawn-intro bareng UFO, partikel slash saat lompat/pantulan, respawn, reset objek. |
| `game_manager.gd` | `Node` (autoload `GameManager`) | Daftar 18 path level, unlock/complete, progres `user://progress.cfg`, reset progres, perpindahan level. |
| `scene_transition.gd` | `Node` (autoload `SceneTransition`) | Tirai kiri/kanan + animasi `Asset/Transisi/Transisi.tscn` saat ganti scene; meminta fade-out BGM dan memulai BGM scene tujuan. |
| `audio_manager.gd` | `Node` (autoload `AudioManager`) | BGM menu/gameplay, bus `Music`, loop, fade-in 0,9 dtk, fade-out 0,3 dtk + `stop()`, dan pengaturan volume tersimpan. |
| `main_menu.gd` | `Control` | Tombol menu, animasi hover/klik, panel 3 round × 6 level (18 tombol), slide antar-round, tombol Next/Back, banner teks round, state tombol Lock/Unlock/Complete, dan membuka panel Level bila datang dari tombol Level pause. |
| `pause.gd` | `Control` | Pause game, animasi panel dan tombol, Resume/Restart/Level/Settings, serta sinkronisasi slider volume. |
| `checkpoint.gd` | `AnimatedSprite2D` | Area `CheckpointArea`; animasi `Sebelum`/`Sesudah`; simpan posisi pemain. |
| `level_portal.gd` | `Area2D` | Selesaikan level, tarik pemain ke portal 1,5 dtk, lanjut ke level berikutnya. |
| `phi_trampoline.gd` | `StaticBody2D` | Papan pantul berbentuk Φ; animasi `Idle`/`Trigger`; pantul ke atas. |
| `enemy_alpha.gd` | `CharacterBody2D` | Musuh patroli α; bisa diinjak; mati lalu respawn saat pemain respawn. |
| `ufo_animation.gd` | `Sprite2D` | Animasi datang/pergi UFO Ω saat pemain spawn (tanpa collider bahaya). |
| `disappearing_platform.gd` | `StaticBody2D` | Platform berkedip → hilang → muncul lagi; reset saat pemain respawn. |
| `moving_platform.gd` | `AnimatableBody2D` | Platform bergerak bolak-balik horizontal (tween tak hingga). |
| `rotating_platform.gd` | `AnimatableBody2D` | Platform berputar terus searah/berlawanan jarum jam. |
| `rotating_saw.gd` | `Node2D` (`@tool`) | Satu mata gergaji × mengorbit; frame `x_putar_01..12.png`. |
| `multi_rotating_saw.gd` | `Node2D` (`@tool`) | 2–3 mata gergaji × mengorbit; node blade dibuat saat runtime. |
| `large_gear.gd` | `AnimatedSprite2D` | Gergaji besar bergerak horizontal dengan `HazardArea`; hanya dipakai Level 5. |

### 4.2 Scene reusable di `Script/` (7 file `.tscn`)

`character_scene.tscn` (sprite Φ mandiri; **tidak pernah di-instance**), `disappearing_platform.tscn` (dipakai Level 2–5), `moving_platform.tscn` (**tidak pernah di-instance**; skripnya dipasang langsung di level), `multi_rotating_saw.tscn` (dipakai Level 3–5), `phi_trampoline.tscn` (dipakai Level 4–5), `rotating_saw.tscn` (dipakai Level 3–5), `pause.tscn` (di-instance di keenam scene level).

**Tidak ada** `rotating_platform.tscn` — skrip `rotating_platform.gd` dipasang langsung pada node di Level 2–5. Pemain juga selalu berupa node inline bernama `Player` di tiap level, bukan instance `character_scene.tscn`.

### 4.3 Manajemen progres & transisi

- `GameManager.LEVEL_SCENES` kini mendeklarasikan **18** entri (`Level 1.tscn` … `Level 18.tscn`, untuk 3 round × 6 level), tetapi yang ada di disk hanya **6** (`Level 1.tscn`–`Level 6.tscn`). `_get_available_level_count()` berhenti pada scene pertama yang missing, jadi jumlah level efektif = **6**. Tombol level 7–18 tetap terkunci sampai scene-levelnya dibuat.
- Progres disimpan di `user://progress.cfg` lewat `ConfigFile` (`highest_unlocked_level`, `completed_levels`).
- `SceneTransition.change_scene()` membuat `CanvasLayer` layer 100, dua `ColorRect` tirai warna `#030817` (0,3 dtk), ganti scene, lalu memutar animasi `Transisi.tscn` (48 frame: `BG kosong`, `Partikel masuk`, `Player terbang`, `Ekor partikel`) sebelum tirai dibuka.

### 4.4 Sistem Audio (`AudioManager`)

| File BGM | Digunakan di |
| :--- | :--- |
| `Audio/BGM/BGM Main menu.mp3` | `Scene/Main Menu.tscn` |
| `Audio/BGM/BGM Gameplay.mp3` | Semua scene level (Level 1–5) |

Alur yang terpasang:

- Bus **`Music`** dibuat saat runtime oleh `AudioManager` (jika belum ada) dan diarahkan ke `Master`. `AudioStreamPlayer` BGM memakai bus tersebut, sehingga slider MUSIC langsung mengendalikan volume BGM.
- Kedua MP3 diimpor dengan `loop=true`; skrip juga menetapkan `loop = true` pada `AudioStreamMP3` sebagai pengaman.
- BGM dipilih otomatis dari scene aktif: menu → BGM menu, level → BGM gameplay. Membuka/menutup panel Settings atau Level Select **tidak** mengganti scene, sehingga BGM tidak restart.
- Saat scene akan diganti (tombol PLAY, pilih level, portal finish, dll.), `SceneTransition.change_scene()` memanggil `AudioManager.fade_out_and_stop()`: volume turun ke −40 dB dalam 0,3 dtk lalu `stop()`. Selama transisi tidak ada BGM yang diputar.
- Setelah scene tujuan dimuat dan tirai selesai dibuka, BGM scene tujuan baru mulai `play()` dengan fade-in 0,9 dtk dari −40 dB ke 0 dB (volume target berasal dari bus `Music`).
- Nilai slider MUSIC dan SFX disimpan di `user://settings.cfg`. Keduanya kini benar-benar mengendalikan bus `Music` dan `SFX`.

**SFX** — 17 file MP3 di `Audio/SFX/` dimuat sekali saat `AudioManager` siap dan diputar lewat kumpulan `AudioStreamPlayer` (12 player bergilir, bus `SFX`) agar beberapa suara bisa terdengar bersamaan:

| Key | File | Pemicu |
| :--- | :--- | :--- |
| `breath_idle` | `Breath For Idle.mp3` | Player diam di lantai; mulai setelah 1 dtk, diulang dengan jeda 1 dtk setelah suara selesai |
| `jump` / `double_jump` | `Jump.mp3` / `Double Jump.mp3` | Lompat pertama / lompat kedua di `player.gd` |
| `landing` | `Landing.mp3` | Saat player menyentuh platform setelah melayang |
| `button_click` / `button_hover` | `SFX Button Clicked.mp3` / `SFX Button Hover.mp3` | Klik dan hover tombol di menu maupun pause |
| `checkpoint` | `SFX Check Point.mp3` | Checkpoint berhasil diaktifkan |
| `death_fall` / `death_blade` / `death_enemy` | `SFX Death Jatuh.mp3` / `SFX Death Terkena Pisau.mp3` / `SFX Death Terkena Enemy.mp3` | `player.die(reason)` — jatuh, gergaji, atau musuh |
| `portal` | `SFX Go Portal.mp3` | Player masuk portal finish |
| `stomp` | `SFX Menginjak Enemy.mp3` | Player menginjak musuh dari atas |
| `spawn` | `SFX Spawn Player.mp3` | Muncul dari UFO dan setelah respawn |
| `ufo_arrival` | `SFX UFO Datang.mp3` | UFO mulai turun saat spawn player |
| `transition` | `Transition SFX.mp3` | Transisi antar-scene dimulai (bersamaan dengan BGM fade-out) |
| `text_intro` | `SFX Text intro.mp3` | Setiap huruf yang muncul pada narasi intro level |
| `ui_open` | `SFX UI Pop Open.mp3` | Panel Level/Settings di menu serta panel Pause/Settings di pause |

`AudioManager` ber-`process_mode = ALWAYS`, sehingga SFX tombol tetap terdengar walaupun game sedang di-pause.

### 4.5 Intro Narasi Level

`Script/Intro Text level.tscn` + `Script/intro_text_level.gd` dipasang di **Level 1 dan Level 6** dalam `"Intro Layer"` (`CanvasLayer`, layer 80). Font **`Madiosa.ttf`** (`Asset/Intro Level/Madiosa.ttf`) dipakai pada `Main Text` **dan `Click enter`** — lengkap untuk huruf, angka, dan tanda baca. Font lama `Transcity DEMO.otf` sudah dihapus dari asset dan referensinya di scene diganti ke Madiosa.

- Pemain tetap terkunci (`player.narrative_active = true`) dari UFO selesai sampai narasi berakhir; sinyal `spawn_intro_finished` memicu narasi.
- Teks muncul per huruf (typewriter, SFX `text_intro` tiap huruf). `Enter` saat masih mengetik → langsung tampilkan kalimat penuh; `Enter` berikutnya → kalimat dihapus dari belakang lebih cepat, lalu lanjut kalimat berikutnya. Label `Click enter` berdenyut (fade).
- **Level 1**: 3 kalimat narasi; setelah kalimat terakhir di-enter, intro hilang dan pemain boleh bergerak.
- **Level 6**: 5 kalimat (termasuk "apakah kamu yakin ingin lanjut"). Setelah kalimat terakhir, tombol `Yes Button` dan `Back To menu Button` muncul ber-pop; Yes → `Main Text` berubah menjadi hitung mundur yang bisa diatur (`countdown_seconds`, default 60 dtk) dengan animasi pop, lalu gameplay dimulai; Back → transisi ke menu. Saat waktu habis: input dimatikan, kamera digoyang selama `shake_duration` (default 0,6 dtk), jeda `fail_pause_seconds` (default 1 dtk), animasi Death diputar **tanpa SFX dan tanpa respawn**, jeda 1 dtk, lalu transisi ke Main Menu dengan panel Level terbuka. Jika pemain berhasil masuk portal tepat waktu, transisi juga menuju Main Menu dengan panel Level terbuka. Kematian saat countdown **tidak** mengulang waktu — hitungan tetap berjalan; tombol Yes/Back dan Enter memiliki pengaman terhadap pemicu ganda.
- Countdown Level 6 memakai ukuran font **50** (`COUNTDOWN_FONT_SIZE`). Saat sisa waktu ≤ **20 detik** (`URGENT_SECONDS`), teks berubah merah dan melakukan pop-up berulang (skala 1,0 ↔ 1,2 tiap 0,22 dtk) hingga waktu habis atau transisi.
- Tombol Yes/Back memiliki efek hover dan klik pop-up serta SFX tombol.

### 4.6 Sistem Pause

`Script/pause.tscn` + `Script/pause.gd` di-instance di **Level 1–5** di dalam node `"Pause Layer"` (`CanvasLayer`, `layer = 90`, `process_mode = ALWAYS`). Level 6 tidak memuat pause. `CanvasLayer` membuat UI pause tetap menempel pada tampilan kamera/ viewport dan tidak ikut bergeser saat `Camera2D` pemain bergerak atau zoom; layer 90 berada di bawah layer transisi (100). Instance `Pause` juga ber-`process_mode = ALWAYS` agar tetap merespons saat `get_tree().paused = true`.

- Tombol pause (kanan atas) membesar saat hover dan pop saat diklik.
- Saat diklik: game di-pause, lalu `Pause Panel` beranimasi — `self_modulate` 0 → `Color(0,0,0,0.6)` cepat; `BG` dan `Akar` jatuh dari atas bersamaan, pop, lalu mengecil dan turun sedikit; setelah itu `Text`, `Restart Button`, `Level Buttons`, `Settings Button`, dan `Resume Button` muncul pop satu per satu.
- Semua tombol panel memiliki efek pop-up saat hover maupun klik.
- **Resume**: panel `self_modulate` → 0 disertai pop, lalu panel disembunyikan dan game dilanjutkan.
- **Restart**: transisi antar-scene lalu memuat ulang scene level yang sama dari awal.
- **Level**: transisi ke `Main Menu.tscn` dengan panel Level terbuka (lewat `GameManager.open_levels_panel_on_menu`).
- **Settings**: membuka panel Settings di dalam pause dengan perilaku sama seperti di menu (slider MUSIC/SFX, pop-up, Reset Progres). Bedanya, **Reset Progres** di pause mereset level lalu melakukan transisi ke Main Menu.

---

## 5. Entitas / Simbol yang Benar-benar Ada

| Elemen visual | Nama implementasi | Node / skrip | Keterangan |
| :--- | :--- | :--- | :--- |
| **Φ** | Pemain | `CharacterBody2D` inline + `player.gd` | Sprite frames `Idle` (6), `Jump` (8), `Death` (8). **Tidak ada animasi `Run`**. |
| Slash lompat | Efek partikel | `CPUParticles2D` "JumpSlashParticles" (dibuat runtime oleh `player.gd`) | Memakai `Efek partikel slash lompat.png`, dipancarkan dari tengah bawah pemain saat lompat/double jump/pantulan. **14 partikel sangat kecil** per emisi (skala `0,03`–`0,065`, spread 42°), lifetime `0,3` dtk, `one_shot = true`, `local_coords = false`. Arah dan `tangential_accel` dibalik sesuai arah gerak: gerak kiri → slash meliuk kanan, gerak kanan → slash meliuk kiri. |
| **θ** | Portal finish | `Area2D` + `AnimatedSprite2D` + `level_portal.gd` | 24 frame `Portal Theta 01..24.png` (dua folder: `Asset/Portal/` dan `Asset/Karakter/Portal/`). |
| **λ** | Checkpoint | `AnimatedSprite2D` + child `Area2D` + `checkpoint.gd` | 12 frame `Sebelum` + 12 frame `Sesudah`. |
| **−** | Platform statis | `StaticBody2D` | Menggunakan `Asset/Level Asset/Minus 1.png`. |
| **− (bergerak)** | Moving platform | `AnimatableBody2D` + `moving_platform.gd` | Node inline; sebagian besar dioverride pada `travel_distance`/`move_speed`/`start_direction`. |
| Segitiga / setengah persegi | Rotating platform | `AnimatableBody2D` + `rotating_platform.gd` | Aset `Segitiga.png` dan `Setengah persegi.png`; default 90°/detik. |
| **+ / √ (klaim lama)** | — | — | **Tidak ada** aset "+" maupun akar. Platform hilang memakai `Minus 1.png` yang memudar; papan pantul memakai simbol **Φ**. |
| **Φ (pantul)** | Phi trampoline | `StaticBody2D` + `phi_trampoline.gd` | 8 frame `phi_dipijak_*` + 6 frame `phi_idle_*`; default `700 px/s`, dioverride `1200` di Level 4–5. |
| **×** | Gergaji berputar | `rotating_saw.gd` / `multi_rotating_saw.gd` | 12 frame `x_putar_01..12.png` + `Revolusi FIX.png` (panduan orbit). |
| **α** | Musuh patroli | `CharacterBody2D` + `enemy_alpha.gd` | Aset `Ngesot *` / `Mati *`; animation name di level = `Idle`/`Death` (**tanpa RayCast2D**; batas patroli pakai jarak + `is_on_wall()`). |
| **Ω** | UFO | `Sprite2D` + `ufo_animation.gd` | Aset `UFO Omega.png`; **hanya visual spawn**, tidak membunuh pemain. |
| Gergaji besar | Large gear | `AnimatedSprite2D` + `large_gear.gd` | 12 frame `Gerigi 01 1..12 1.png` + `Track Gerigi Besar.png`; **khusus Level 5**. |

Semua level juga memakai `BackGround.jpg` berulang pada `ParallaxBackground` (5/6/8/11/12 `ParallaxLayer`). **Tidak ada** aset simbol melayang bercahaya (Φ, θ, Ω, π, Δ) di latar — klaim README lama tidak sesuai.

---

## 6. Isi Scene yang Terpasang

### 6.1 `Scene/Main Menu.tscn`

Root `Control` + `main_menu.gd`. Anak: background `TextureRect` berisi `AnimatedSprite2D` (8 frame `SYMBOLED • Background 01..08.png`, loop, speed 7), `MenuButtons` (`PlayButton`, `LevelsButton`, `SettingsButton`, `QuitButton`), `"Settings Panel"`, `Transisi Kiri` / `Transisi Kana` (keduanya tersembunyi), dan **`"Panel panel"`** (awalnya `visible = false`, `clip_contents = true`) sebagai panel pilihan level.

Struktur `"Panel panel"`:
- `"Round 1"` berisi `Level 1`–`Level 6`, `"Round 2"` berisi `Level 7`–`Level 12`, `"Round 3"` berisi `Level 13`–`Level 18`. Ketiganya memakai tekstur `Panel Levels 1–10 • Empty.png` dan saling menimpa pada posisi yang sama; hanya round aktif yang terlihat.
- `"Round Text"` (`Box Text.png`) berisi `Round Label` bertipe `Label` yang menampilkan `ROUND 1/2/3`. **Teksnya** yang dirata-tengah di dalam kotak (`horizontal_alignment = 1`, `vertical_alignment = 1`, font 42, warna ungu gelap), bukan hanya posisi nodenya. `TextEdit` diganti `Label` karena `TextEdit` tidak memiliki properti perataan teks. Banner diberi warna biru neon, animasi muncul + meluncur dari tengah, dan `Round Label` terus berdenyut (skala 1,00–1,06 + pergantian warna) agar terlihat pemain; `mouse_filter = IGNORE` agar tidak menghalangi klik tombol level.
- `"Next Button"` memakai `Kana.png` (panah kanan), `"Bacck Button"` memakai `Kiri.png` (panah kiri; ejaan node sengaja mengikuti scene), dan `"Close Button"` memakai `Button • Close.png`.
- Judul `Text • LEVELS.png` juga tetap ada di panel.

Aturan navigasi round (di `main_menu.gd`):
- Round berikutnya hanya bisa dibuka bila **keenam level** di round aktif berstatus selesai. Jika level keenam (atau level lain di round itu) belum selesai, `Next Button` dinonaktifkan; pada Round 3 tombol Next juga dinonaktifkan karena tidak ada round berikutnya.
- Di Round 1, `Bacck Button` disembunyikan; tombol itu baru muncul di Round 2 dan 3.
- Perpindahan round memakai tween **slide** berlawanan arah (0,38 dtk, `TRANS_CUBIC`/`EASE_IN_OUT`) dengan round lama keluar dan round baru masuk.
- Semua tombol, termasuk Next/Back, memakai efek **pop-up**: hover membesar ke 1,12; klik menyusut ke 0,88 lalu membesar ke 1,14 sebelum kembali. Untuk Next/Back, efek hover tetap berjalan walaupun tombol dalam keadaan `disabled`.
- Next/Back juga dibedakan warnanya: **enabled** = putih cerah (`Color(1,1,1,1)`), **disabled** = abu kebiruan redup (`Color(0.42,0.45,0.55,0.75)`), dengan transisi halus 0,15 dtk saat status berubah.

Fakta penting lainnya:
- `"Settings Panel"` mengikuti contoh `Asset/Menu/Settings/Contoh Layout Settings.png`: judul SETTINGS, dua slider bertipe **`HSlider`** (`"Music Slidder"` dan `"SFX Slidder"`, memakai `MUSIC • Handle.png` serta `StyleBoxTexture` kustom, rentang 0–100, langkah 1), label nilai persentase dinamis sebagai child tiap slider, tombol `Reset Progres Button`, dan `Close Button` (keduanya langsung di bawah `"Settings Panel"`). Panel tersembunyi saat awal.
- Slider MUSIC mengubah volume bus `Music` lewat `AudioManager.set_music_volume()`; slider SFX hanya menyimpan nilai (belum ada audio SFX). Kedua slider pop-up saat hover dan saat nilai diubah; tombol Reset/Close pop-up saat diklik; panel Settings muncul dan hilang dengan animasi pop-up.
- `Reset Progres Button` memanggil `GameManager.reset_progress()`: `highest_unlocked_level` kembali ke 1 dan semua `completed_levels` dikosongkan lalu disimpan ke `user://progress.cfg`.
- Membuka/menutup Settings tidak mengganti scene, sehingga BGM menu tetap berjalan tanpa restart.
- Tekstur state tombol `Lock`, `Unlock`, dan `Complete` hanya tersedia untuk level 1–10. Untuk level 11–18, skrip mempertahankan tekstur sementara yang sudah dipasang di scene karena berkas tekstur bernomor tersebut tidak ada.
- Karena baru ada 6 scene level, level 7–18 belum bisa diselesaikan; Next Round 2 hanya bisa aktif jika keenam level di Round 1 (level 1–6) berstatus selesai.
- Tombol `Level 10` masih memiliki `flip_h = true` (kemungkinan sisa edit).

### 6.2 Level 1–6

Keenam level ber-root `Node2D` **tanpa skrip**, dengan struktur berulang: `ParallaxBackground`, `Platform` (`StaticBody2D`), satu `Player` (`CharacterBody2D` + kamera `zoom 1.5`; `limit_left = -60` di Level 1, `-40` di Level 2–6), satu `UFO`, satu `Portal`, checkpoint, dan berbagai hazard/platform. Kamera **tanpa position smoothing**. Level 1–5 memuat instance `Script/pause.tscn` bernama `Pause`; Level 1 dan Level 6 juga memuat instance `Intro Text level.tscn` di dalam `"Intro Layer"` (`CanvasLayer`, layer 80). `Level 6.tscn` kini lebih pendek dan tidak memuat pause.

| Konten | L1 | L2 | L3 | L4 | L5 | L6 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Checkpoint | 1 | 1 | 2 | 2 | 2 | 0 |
| Platform hilang (instance + inline) | 1 | 3 | 4 | 4 | 5 | 4 |
| Moving platform | 0 | 1 | 3 | 4 | 3 | 1 |
| Rotating platform | 0 | 2 | 3 | 3 | 4 | 3 |
| Rotating saw | 0 | 0 | 2 | 5 | 4 | 4 |
| Multi-rotating saw | 0 | 0 | 1 | 1 | 2 | 1 |
| Phi trampoline | 0 | 0 | 0 | 1 | 1 | 1 |
| Enemy Alpha | 0 | 0 | 0 | 3 | 4 | 2 |
| Gerigi besar | 0 | 0 | 0 | 0 | 2 | 1 |
| ParallaxLayer | 5 | 6 | 8 | 11 | 12 | 12 |
| Player / Kamera / Portal / UFO | 1 | 1 | 1 | 1 | 1 | 1 |

**Level 1** — Pengenalan: platform statis menanjak, satu checkpoint (x≈1174), satu platform hilang inline (x≈3068, `disappear_delay=0.6`, `respawn_delay=4.0`), portal di x≈4079. Tidak ada instance scene reusable. UFO memakai `arrival_duration = departure_duration = 2.0`.

**Level 2** — Platform dinamis: 3 platform hilang (2 instance + 1 inline), checkpoint x≈2599, moving platform `travel_distance=500` x≈3060, rotating platform segitiga x≈4401 dan setengah persegi x≈5735, portal x≈6432.

**Level 3** — Presisi & gergaji: 2 rotating saw (x≈1371/1630, orbit 60, kecepatan 125/130; salah satu berlawanan jarum jam), 4 platform hilang, 3 rotating platform, 3 moving platform (termasuk `travel_distance=1000`, `move_speed=150`), 2 checkpoint, multi-saw 2 blade x≈7024, portal x≈8562.

**Level 4** — Musuh & pantulan: 5 rotating saw, 1 multi-saw, 4 platform hilang, 4 moving platform, 3 rotating platform (salah satu berlawanan jarum jam), **trampoline Φ `trampoline_velocity=1200`** x≈5225 yang meluncurkan pemain ke jalur atas, 3 Enemy Alpha (jarak patroli 170–180), 2 checkpoint, portal tinggi di x≈10866 / y≈−387.

**Level 5** — Ujian akhir & paling lengkap: 4 rotating saw, 2 multi-saw (salah satu `revolution_speed=70`, orbit 190), 5 platform hilang, 3 moving platform, 4 rotating platform, 1 trampoline Φ (1200), 4 Enemy Alpha (dua di antaranya `move_speed=120`), **2 gerigi besar** (`left_limit_x=-200`, `right_limit_x=200`, `move_speed=140`), 2 checkpoint, portal akhir x≈12403.

**Level 6** — Final Round 1: 12 `ParallaxLayer`, 4 platform hilang, 1 moving platform, 3 rotating platform, 4 rotating saw, 1 multi-saw, 1 trampoline Φ (1000), 2 Enemy Alpha, 1 gerigi besar, **tanpa checkpoint dan tanpa Pause**, satu Portal di x≈7520. Narasi intro dengan countdown 120 dtk; bila waktu habis, pemain kembali ke menu dengan panel Level terbuka.

### 6.3 Level 7–12 (Round 2)

Keenam scene ini **dirancang ulang dari nol**, bukan salinan Level 5/6. Tiap level memakai rantai platform buatan sendiri: segmen lantai berupa `RectangleShape2D` unik (`SegmentShape0…`) yang ditempatkan pada koordinat yang direncanakan, dengan jarak lompat 150–160 px dan kenaikan permukaan 40–120 px. Hanya aset seni, `SpriteFrames`, dan skrip yang dipakai ulang dari Level 5 — tata letak, jumlah segmen, dan penempatan hazard berbeda di setiap level.

| Konten | L7 | L8 | L9 | L10 | L11 | L12 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Segmen platform | 12 | 13 | 14 | 15 | 16 | 10 |
| Rotating saw | 4 | 5 | 6 | 7 | 8 | 6 |
| Multi-rotating saw | 2 | 3 | 4 | 4 | 5 | 3 |
| Platform hilang | 3 | 4 | 4 | 5 | 5 | 4 |
| Moving platform | 2 | 2 | 2 | 2 | 2 | 2 |
| Rotating platform | 2 | 3 | 3 | 3 | 4 | 2 |
| Enemy Alpha | 3 | 4 | 5 | 5 | 6 | 3 |
| Gerigi besar | 1 | 1 | 1 | 1 | 2 | 2 |
| Trampoline Φ | 1 | 1 | 2 | 2 | 2 | 1 |
| Checkpoint | 2 | 2 | 2 | 2 | 2 | 0 |
| Pause | ya | ya | ya | ya | ya | tidak |
| Intro | tidak | tidak | tidak | tidak | tidak | tidak |

**Level 7** — 12 segmen sepanjang ≈10.200 px, gap 150–170 px, empat rotating saw di tepi jurang, dua multi-saw, dua moving platform sebagai jembatan, satu gerigi besar, trampoline Φ, dan dua checkpoint. Kecepatan hazard ×1,10 — sedikit di atas Level 5.

**Level 8–11** — Rantai platform memanjang (13/14/15/16 segmen) dengan variasi ketinggian makin curam; faktor kecepatan ×1,18 / ×1,25 / ×1,32 / ×1,40, `disappear_delay` 0,80 → 0,65, `respawn_delay` 1,15 → 1,30, serta penambahan saw, multi-saw, dan musuh di setiap level.

**Level 12** — Final Round 2 dengan 10 segmen yang **mendaki**: permukaan naik dari y≈560 ke y≈320, tetapi semua lompatan masih dalam jangkauan double-jump; trampoline Φ membantu transisi awal. **Tanpa checkpoint dan tanpa Pause**, narasi intro sengaja dihapus dulu (gameplay diprioritaskan), kecepatan hazard ×1,45. Portal Level 12 kembali ke Main Menu dengan panel Level terbuka.

**Catatan unlock:** `get_highest_unlocked_level()` kini juga membaca `completed_levels`. Level 6 yang diselesaikan sebelum scene Level 7 ada tetap membuka tombol Level 7 setelah scene tersebut tersedia.

---

## 7. Struktur Direktori (Sama Persis dengan Proyek)

```
project/
├── .editorconfig
├── .gitattributes
├── .gitignore
├── .godot/
├── Audio/
│   ├── BGM/
│   │   ├── BGM Main menu.mp3 (+ .import)
│   │   └── BGM Gameplay.mp3 (+ .import)
│   └── SFX/                         (17 file .mp3 + .import: Breath For Idle, Jump,
│                                    Double Jump, Landing, SFX Button Clicked/Hover,
│                                    SFX Check Point, SFX Death Jatuh/Terkena Pisau/
│                                    Terkena Enemy, SFX Go Portal, SFX Menginjak Enemy,
│                                    SFX Spawn Player, SFX UFO Datang, SFX Text intro,
│                                    Transition SFX, SFX UI Pop Open)
├── Asset/
│   ├── Check Point/
│   │   ├── check point sebelum/     (Checkpoint_Before_01..12.png + .import)
│   │   └── check point sesudah/     (Checkpoint_After_01..12.png + .import)
│   ├── Enemy Alpha/
│   │   ├── Enemy Alpha idle/        (Ngesot 01..06.png + .import)
│   │   └── Enemy Alpha mati/        (Mati 01..06.png + .import)
│   ├── Gerigi Besar/                (Gerigi 01 1..12 1.png, Track Gerigi Besar.png + .import)
│   ├── Gerigi pisau/                (x_putar_01..12.png, Revolusi FIX.png + .import)
│   ├── Intro Level/                 (Yes button.png, Back to menu button.png,
│   │                                Orbitron PERSONAL USE ONLY!.ttf + .import)
│   ├── Karakter/
│   │   ├── Death 01..08.png, Idle 01..06.png, Jump 01..08.png,
│   │   │   Efek partikel slash lompat.png (+ .import)
│   │   └── Portal/                  (Portal Theta 01..24.png + .import)
│   ├── Level Asset/                 (BackGround.jpg, Minus 1.png, Segitiga.png,
│   │                                Setengah persegi.png, UFO Omega.png + .import)
│   ├── Menu/
│   │   ├── Backhgorund/             (SYMBOLED • Background 01..08.png + .import)
│   │   ├── Button/                  (Button_Play/Levels/Settings/Quit-removebg-preview.png + .import)
│   │   ├── Buttton levels/          (Panel, Text LEVELS, Close, Box Text, Kana, Kiri,
│   │                                State=Lock/Unlock/Complete, Level=1..10.png + .import)
│   │   └── Settings/                (panel, Contoh Layout Settings, teks, ikon, aset slider MUSIC/SFX + .import)
│   ├── Pause/                       (Pause button, PAUSED, Dark panel, Neon square root border,
│   │                                Resume/Restart/Levels/Settings button, White neon core + .import)
│   ├── Phi/
│   │   ├── Phi idle/                (phi_idle_01@2x .. phi_idle_08.png + .import)
│   │   └── Phi trigger/             (phi_dipijak_01..08.png + .import)
│   ├── Portal/                      (Portal Theta 01..24.png + .import; duplikat Karakter/Portal)
│   └── Transisi/                    (Transisi 01..48.png + .import, Transisi.tscn)
├── Scene/
│   ├── Level 1.tscn
│   ├── Level 2.tscn
│   ├── Level 3.tscn
│   ├── Level 4.tscn
│   ├── Level 5.tscn
│   ├── Level 6.tscn
│   └── Main Menu.tscn
├── Script/
│   ├── Intro Text level.tscn
│   ├── audio_manager.gd
│   ├── character_scene.tscn
│   ├── checkpoint.gd
│   ├── intro_text_level.gd
│   ├── checkpoint.gd.uid
│   ├── disappearing_platform.gd
│   ├── disappearing_platform.gd.uid
│   ├── disappearing_platform.tscn
│   ├── enemy_alpha.gd
│   ├── enemy_alpha.gd.uid
│   ├── game_manager.gd
│   ├── game_manager.gd.uid
│   ├── large_gear.gd
│   ├── large_gear.gd.uid
│   ├── level_portal.gd
│   ├── level_portal.gd.uid
│   ├── main_menu.gd
│   ├── main_menu.gd.uid
│   ├── moving_platform.gd
│   ├── moving_platform.gd.uid
│   ├── moving_platform.tscn
│   ├── multi_rotating_saw.gd
│   ├── multi_rotating_saw.gd.uid
│   ├── multi_rotating_saw.tscn
│   ├── pause.gd
│   ├── pause.tscn
│   ├── phi_trampoline.gd
│   ├── phi_trampoline.gd.uid
│   ├── phi_trampoline.tscn
│   ├── player.gd
│   ├── player.gd.uid
│   ├── rotating_platform.gd
│   ├── rotating_platform.gd.uid
│   ├── rotating_saw.gd
│   ├── rotating_saw.gd.uid
│   ├── rotating_saw.tscn
│   ├── scene_transition.gd
│   ├── scene_transition.gd.uid
│   ├── ufo_animation.gd
│   └── ufo_animation.gd.uid
├── GD.md
├── icon.svg
├── icon.svg.import
├── Log Open Code.md
├── Log Prompt Co-pilot.md
├── project.godot
└── README.md
```

### Inventaris aset

`Asset/` berisi **22 folder**, **519 file**: 258 `.png`, 1 `.jpg` (`BackGround.jpg`), 259 `.import`, dan 1 `.tscn` (`Transisi.tscn`). Dua file BGM `.mp3` berada di luar `Asset/`, yaitu di `Audio/BGM/`.

Ada **2 file BGM MP3** di `Audio/BGM/` (menu dan gameplay) dan **17 file SFX MP3** di `Audio/SFX/`. Slider MUSIC dan SFX keduanya aktif mengendalikan bus masing-masing.

---

## 8. Status Implementasi & Koreksi terhadap Dokumen Lama

Fitur yang **tidak ada** di proyek dan karenanya dihapus dari dokumen ini:

| Klaim README lama | Fakta di proyek |
| :--- | :--- |
| Tombol lompat `Spasi` / `W` / `Up` | Tidak ada; lompat terjadi saat menekan `A`/`D`/arrow (sekali = lompat pertama, dua kali = double jump). |
| Animasi `idle`, `run`, `jump` + squash/stretch pada karakter | Hanya `Idle`, `Jump`, `Death`; squash/stretch ada di tween spawn UFO/karakter dan portal, bukan animasi `run`. |
| Simbol `+` sebagai bounce/rotating pad, `√` sebagai platform hilang | Tidak ada aset "+" atau "√"; papan pantul = **Φ**, platform hilang = `Minus 1.png` yang memudar. |
| Ω sebagai musuh terbang berbahaya | UFO hanya animasi kedatangan/keberangkatan saat spawn; tanpa Area2D bahaya. |
| Musuh α memakai `RayCast2D` | Tidak ada `RayCast2D`; patroli memakai batas jarak + `is_on_wall()`. |
| Kamera dengan *position smoothing* | `Camera2D` anak pemain, zoom 1.5, tanpa smoothing. |
| BGM synthwave/lo-fi + SFX retro | Sudah ada 2 BGM MP3 dan 14 SFX MP3 yang diputar `AudioManager` melalui bus `Music` dan `SFX`. |
| 5 level "dirancang", pengaturan (Settings) berfungsi | 6 level benar-benar ada, tetapi kini 18 dideklarasikan untuk 3 round; Settings kini berfungsi (slider MUSIC/SFX, reset progres); tidak ada layar ending. |
| Latar parallax berisi simbol matematik bercahaya | Latar hanya pengulangan `BackGround.jpg` pada `ParallaxLayer`. |

### Catatan/anomali teknis yang nyata

- `character_scene.tscn` dan `moving_platform.tscn` tidak pernah di-instance; nodenya diduplikasi inline di tiap level.
- `rotating_saw.gd` mengganti frame `"default"` dari scene dengan animasi `"Spin"` yang dibuat runtime dari 12 PNG.
- Animasi memakai nama campuran: Inggris (`Idle`, `Jump`, `Death`, `Trigger`, `Default`, `default`) dan Indonesia (`Sebelum`, `Sesudah`); aset patroli/mati bernama `Ngesot`/`Mati` tetapi animation name di scene = `Idle`/`Death`.
- Ejaan folder/aset yang ada di proyek harus dipakai persis: `Backhgorund`, `Buttton levels`, `SYMBOLED`, `Disappering Platform`, `Transisi Kana`, `Reset Progres Button`; filename memakai karakter Unicode `•` (U+2022), `—` (U+2014), dan `–` (U+2013).
- Level 4 dan 5 memiliki `ParallaxLayer8` dan `ParallaxLayer9` pada posisi x yang sama (8821) — layer ganda.
- `Asset/Portal/` dan `Asset/Karakter/Portal/` berisi 24 frame yang sama persis.
- `project.godot` mengatur Jolt Physics untuk 3D pada proyek 2D (tidak berdampak).
- Semua path `res://` yang dipakai scene/skrip ada di disk, **kecuali** `Level 6.tscn`–`Level 10.tscn` yang memang belum dibuat; kode sudah mengabaikannya dengan aman lewat `ResourceLoader.exists()`.
