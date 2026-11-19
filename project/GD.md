# Symboled — Game Design Document (GDD)

> **Genre:** 2D Minimalist Precision Platformer  
> **Game Engine:** Godot Engine 4.x  
> **Referensi Utama:** *Rodha*, *Jump King*

---

## 1. Gambaran Umum & Latar Cerita (Overview & Story)
**Symboled** adalah game *2D minimalist precision platformer* yang berlatar di sebuah ruang dimensi matematika abstrak. 

### Latar Cerita (Premise)
Di dalam ruang hampa koordinat yang dingin dan gelap, entitas kecil bernama **$\pi$ (Pi)** terperangkap di antara susunan hukum geometri dan jebakan simbol yang tak berujung. Tanpa kemampuan bertarung, satu-satunya cara bagi **$\pi$** untuk bebas dan melintasi dimensi adalah dengan melompati setiap rintangan presisi menuju gerbang dimensi **$\theta$ (Theta)** yang tersedot melintasi ruang hampa.

---

## 2. Gameplay Loop (Alur Permainan)
Permainan berjalan dalam siklus aksi cepat berbasis presisi momentum:
1. **Spawn:** Karakter **$\pi$** muncul di atas platform awal stage.
2. **Navigasi & Lompatan Presisi:** Pemain memperhitungkan sudut dan jarak untuk melompat dari satu pijakan ke pijakan berikutnya sambil menghindari rintangan berbahaya.
3. **Kegagalan & Respawn:** Jika terjatuh ke ruang hampa atau menyentuh rintangan berbahaya, karakter langsung di-*respawn* kembali ke titik awal untuk mencoba lagi secara instan.
4. **Mencapai Portal ($\theta$):** Menyentuh gerbang dimensi **$\theta$** di ujung area untuk memicu animasi transisi melayang melintasi ruang angkasa menuju stage berikutnya.

---

## 3. Mekanik Inti & Kontrol (Core Mechanics & Controls)
**Symboled** tidak memiliki mekanik berjalan biasa (*walk*) maupun tombol lompat terpisah. Seluruh pergerakan karakter bertumpu pada **Directional Hop / Arc Jump**:

* **Kontrol Utama:**
  * **`A` (atau Panah Kiri):** Karakter melompat membusur ke arah **Kiri-Atas** membentuk lintasan parabola.
  * **`D` (atau Panah Kanan):** Karakter melompat membusur ke arah **Kanan-Atas** membentuk lintasan parabola.
* **Fisika Pergerakan:**
  * Lompatan hanya dapat dipicu saat karakter berpijak di atas permukaan platform (`is_on_floor()`).
  * Saat melayang di udara, karakter mengikuti hukum gravitasi 2D dan berotasi mengikuti arah lompatan hingga mendarat kembali.
* **Sistem Respawn:**
  * Terpicu secara otomatis apabila karakter menyentuh area bahaya (*hazard*) atau jatuh melewati batas bawah koordinat level.
  * Karakter langsung dikembalikan ke posisi *spawn* awal tanpa jeda layar *Game Over* yang panjang agar ritme permainan tetap cepat.

---

## 4. Elemen Dunia & Simbol (World & Entities)
Seluruh objek di dalam game direpresentasikan menggunakan simbol matematika dengan fungsi mekanik yang jelas:

| Simbol | Nama Objek | Fungsi & Mekanik |
| :--- | :--- | :--- |
| **$\pi$** *(Pi)* | **Player** | Karakter utama yang dikendalikan pemain dengan mekanik lompat kiri/kanan. |
| **$\theta$** *(Theta)* | **Portal Finish** | Gerbang tujuan akhir setiap stage yang memicu transisi ke stage berikutnya. |
| **$-$** *(Minus)* | **Platform** | Pijakan datar statis maupun bergerak (*moving platform*) tempat karakter mendarat dan bertumpu. |
| **$+$** *(Plus)* | **Bounce / Rotating Platform** | Pijakan pemantul untuk menjangkau area tinggi atau platform yang berputar pada porosnya. |
| **$\sqrt{\phantom{x}}$** *(Akar)* | **Disappearing Platform** | Platform rapuh yang memudar dan menghilang beberapa detik setelah diinjak oleh pemain. |
| **$\times$** *(Kali)* | **Saw-blade Hazard** | Rintangan gerigi berputar berwarna merah neon yang memicu *respawn* saat tersentuh. |
| **$\infty$** *(Loop)* | **Chainsaw Loop Hazard** | Rintangan gergaji mesin memanjang dengan gerigi tajam di sekeliling tepinya yang harus dilompati. |
| **$\Omega$** *(Omega)* | **UFO Hazard** | Entitas melayang di udara sebagai rintangan tambahan pada jalur lompatan. |

---

## 5. Arahan Visual & Audio (Visual & Sound Direction)
* **Visual:** *Minimalist Dark Neon Vector* dengan latar belakang kisi-kisi koordinat (*graph grid*) gelap yang menggunakan sistem *Parallax Background* untuk efek kedalaman ruang.
* **Transisi Antar-Stage:** Layar ruang hampa bertabur partikel cahaya dan simbol matematika kecil berpendar yang bergeser (*slide*) dari kanan ke kiri, menampilkan karakter **$\pi$** melayang seolah tersedot melintasi dimensi.
* **Audio:** Musik latar *chill minimalist synthwave* yang berulang (*loop*) dipadukan dengan efek suara (*SFX*) sintetis minimalis untuk lompatan, pantulan, *respawn*, dan teleportasi portal.