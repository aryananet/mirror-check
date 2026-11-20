# ⚡ Iran Ubuntu Mirror Optimizer & Health Checker

[![Mirror Health](https://github.com/aryananet/mirror-check/actions/workflows/mirror-health.yml/badge.svg)](https://github.com/aryananet/mirror-check/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange.svg)](https://ubuntu.com)

A reliable, safe, and automated CLI tool to test, benchmark, and configure the fastest and freshest Iranian Ubuntu package mirrors.

---

## 🚀 Quick Start (One-Liner)

### 1. Benchmark without making any changes (Dry Run):
```bash
curl -sSL https://raw.githubusercontent.com/aryananet/mirror-check/main/iran-mirrors.sh | bash
```

### 2. Automatically select and apply the fastest mirror:
```bash
curl -sSL https://raw.githubusercontent.com/aryananet/mirror-check/main/iran-mirrors.sh | sudo bash -s -- --auto
```

### 3. Restore your original APT sources:
```bash
curl -sSL https://raw.githubusercontent.com/aryananet/mirror-check/main/iran-mirrors.sh | sudo bash -s -- --restore
```

---

## 📊 Live Verified Mirror Status (November 2026)

| Provider | Mirror URL | Type | Status |
| :--- | :--- | :--- | :--- |
| **ParsPack (Abrha)** | `https://repo.abrha.net/ubuntu` | Cloud / Hosting |  Active & Synced |
| **Ferdowsi Cloud** | `https://mirror.ferdowsi.cloud/artifactory/apt-remote` | Cloud Platform |  Active & Freshly Synced |
| **IUT (Isfahan Univ.)** | `https://repo.iut.ac.ir/repo/ubuntu` | University Network |  Active & Synced |
| **ArvanCloud** | `https://mirror.arvancloud.ir/ubuntu` | CDN / Cloud Edge |  Active & Synced |
| **IranServer** | `https://mirror.iranserver.com/ubuntu` | Data Center |  Active & Synced |
| **Pars Host** | `https://ubuntu.pars.host` | Data Center |  Active & Synced |
| **Sindad Cloud** | `https://ir.ubuntu.sindad.cloud/ubuntu` | Cloud VPS |  Active & Synced |
| **ParsVDS** | `https://ubuntu.parsvds.com/ubuntu` | Data Center |  Active & Synced |
| **Canonical IR** | `http://ir.archive.ubuntu.com/ubuntu` | Official Upstream |  Active & Synced |
| **Mobinhost** | `https://mirror.mobinhost.com/ubuntu` | Data Center | ⚠️ Lagging (>30 days) |

---

## 🎯 Key Features

- **⚡ Real Throughput Benchmark:** Measures true network throughput and HTTP latency, not just small header responses.
- **🛡️ Safe APT Configuration:** Replaces **only** official Ubuntu repository URLs. Preserves third-party PPAs, Docker, NodeSource, Google Chrome, and custom sources.
- **🔄 Sync-Freshness Guard:** Automatically inspects `InRelease` headers to detect and skip desynchronized or lagging mirrors (preventing 404 / Hash sum mismatch errors).
- **💾 Automatic Backups & One-Click Rollback:** Backs up `/etc/apt/sources.list` or `/etc/apt/sources.list.d/ubuntu.sources` before modifying. Restore anytime with `--restore`.
- **🚀 Modern deb822 Support:** Full native support for Ubuntu 24.04 LTS (Noble Numbat) `deb822` format as well as legacy Ubuntu versions (20.04 Focal, 22.04 Jammy).
- **🪶 Zero Heavy Dependencies:** Pure Bash script requiring only `curl` or `wget`. No `bc` or `lsb-release` required.

---

<div dir="rtl">

## 🇮🇷 راهنمای فارسی

ابزاری سبک، سریع و ایمن برای تست سرعت و تنظیم خودکار مخازن اوبونتو روی سرورهای آینه‌ای (Mirror) فعال در داخل ایران (پارس‌پک، ابر فردوسی، دانشگاه صنعتی اصفهان، ابر آروان، ایران‌سرور و ...).

### ویژگی‌های مهم:
1. **تست سرعت واقعی:** اندازه‌گیری دانلود واقعی دیتای پکیج‌ها جهت انتخاب دقیق‌ترین میرور.
2. **پشتیبانی از میرورهای جدید و معتبر:** اضافه شدن مخازن پارس‌پک (`repo.abrha.net`)، ابر فردوسی (`mirror.ferdowsi.cloud`) و دانشگاه صنعتی اصفهان (`repo.iut.ac.ir`).
3. **حفظ مخازن جانبی:** عدم تداخل با داکر (Docker)، نود جی‌اس (Node.js) و PPAها.
4. **پشتیبانی از اوبونتو ۲۴.۰۴ (Noble):** سازگاری خودکار با فرمت جدید `ubuntu.sources`.
5. **بکاپ خودکار و بازگردانی:** امکان بازگردانی به تنظیمات پیشین با دستور `--restore`.

### نحوه اجرا:
```bash
# تست سرعت مخازن:
curl -sSL https://raw.githubusercontent.com/aryananet/mirror-check/main/iran-mirrors.sh | bash

# تنظیم خودکار سریع‌ترین مخزن:
curl -sSL https://raw.githubusercontent.com/aryananet/mirror-check/main/iran-mirrors.sh | sudo bash -s -- --auto

# بازگردانی به حالت اولیه:
curl -sSL https://raw.githubusercontent.com/aryananet/mirror-check/main/iran-mirrors.sh | sudo bash -s -- --restore
```

</div>
