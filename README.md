# mkswap

Script bash untuk membuat swap file di Linux dengan mudah.

## Fitur

- Menu interaktif untuk memilih ukuran swap
- Pilihan ukuran: 2 GB, 4 GB, atau custom
- Otomatis mengatur permission (chmod 600)
- Otomatis memformat swap file
- Otomatis mengaktifkan swap
- Otomatis menambahkan ke `/etc/fstab` agar persisten setelah reboot
- Backup `/etc/fstab` sebelum dimodifikasi
- Fallback ke `dd` jika `fallocate` gagal

## Cara Menggunakan

### Download & Jalankan Langsung

```bash
curl -sSL https://raw.githubusercontent.com/pashamajied/mkswap/refs/heads/main/mkswap.sh | sudo bash
```

atau dengan wget:

```bash
wget -qO- https://raw.githubusercontent.com/pashamajied/mkswap/refs/heads/main/mkswap.sh | sudo bash
```

### Download Manual

```bash
wget https://raw.githubusercontent.com/pashamajied/mkswap/refs/heads/main/mkswap.sh
chmod +x mkswap.sh
sudo ./mkswap.sh
```

## Menu

```
==================================
    Pembuat Swap File
==================================
Pilih ukuran swap yang ingin dibuat:
1. 2 GB
2. 4 GB
3. Custom (input sendiri)
4. Keluar
==================================
```

## Kebutuhan Sistem

- Linux dengan akses root/sudo
- Package: `util-linux` (untuk mkswap, swapon)

## Perintah yang Digunakan

| Perintah | Fungsi |
|----------|--------|
| `fallocate` | Membuat file swap |
| `chmod 600` | Mengatur permission |
| `mkswap` | Memformat sebagai swap |
| `swapon` | Mengaktifkan swap |
| `free -h` | Menampilkan status memori |
| `swapon --show` | Menampilkan info swap |

## Lokasi File

- Swap file: `/swapfile`
- Backup fstab: `/etc/fstab.bak`

## Menghapus Swap

Jika ingin menghapus swap yang sudah dibuat:

```bash
sudo swapoff /swapfile
sudo rm /swapfile
sudo sed -i '/\/swapfile/d' /etc/fstab
```

## Lisensi

MIT
