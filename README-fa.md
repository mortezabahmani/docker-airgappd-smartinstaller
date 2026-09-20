# نصب‌کننده هوشمند Docker برای محیط‌های بدون اینترنت (Air-Gapped)

**ابزار هوشمند نصب Docker Engine** با پشتیبانی از چندین میرور و قابلیت نصب کاملاً آفلاین، و5صوصاً برای محیط‌های جداشانده از شبکه و مناطق دارای محدودیت شبکه‌ای طراحی شده است.

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/mortezabahmani/docker-airgappd-smartinstaller)

> 📖 English documentation is available here → [README.md](README.md)

---

## قابلیت‌ها

| قابلیت | توضیح |
|---------|-------------|
| **دو حالته کاری** | دانلود آنلاین با Fallback روی چندین میرور + نصب خالص آفلاین |
| **غیرتعاملی** | قابل اجرا با پارامترهای `--distro`، `--codename`، `--arch`، `--yes` |
| **صداقت‌سنجی** | تولید و بررسی فایل `SHA256SUMS` |
| **چندمعماره** | پیش‌فرض `amd64`، پشتیبانی از `arm64` با انتخاب صریح کاربر |
| **چندتوزیع** | Ubuntu (resolute, noble, ...) و Debian (trixie, bookworm, ...) |
| **پشتیبانی از پراکسی** | از متغیرهای `http_proxy` و `https_proxy` پیروی می‌کند |
| **Dry-Run** | حالت `--dry-run` برای مشاهده اقدامات بدون اجرا |
| **تست پس از نصب** | اجرای اختیاری `docker run hello-world` |
| **سازگار با Bash 3.2+** | روی macOS و لینوکس‌های جدید کار می‌کند |

---

## سیستم‌عامل‌های پشتیبانی‌شده

| توزیع | کدنام | کاربرد معمول |
|----------|--------|-------------|
| Ubuntu 26.04 LTS | `resolute` | سرور پروداکشن |
| Ubuntu 24.04 LTS | `noble` | محیط‌های LTS |
| Debian 13 | `trixie` | دسکتاپ توسعه (مانند MX Linux 25) |
| Debian 12 | `bookworm` | سرورهای پایدار |

---

## شروع سریع

```bash
chmod +x install-docker-smart.sh
./install-docker-smart.sh
```

اسکریپت بهصورت تعاملی شما را هدایت می‌کند.

### نمونه غیرتعاملی

```bash
./install-docker-smart.sh \
  --distro ubuntu \
  --codename resolute \
  --arch amd64 \
  --yes
```

### نصب خالص آفلاین

```bash
sudo ./install-docker-smart.sh --offline /path/to/docker-packages
```

---

## گزینه‌های خط فرمان

```
--distro <ubuntu|debian>     توزیع هدف
--codename <name>            کدنام (resolute, trixie, noble, bookworm, ...)
--arch <amd64|arm64>         معماری (پیش‌فرض: amd64)
--offline <dir>              نصب آفلاین از پوشه مشخص
--yes, -y                    حالت غیرتعاملی
--dry-run                    نمایش اقدامات بدون اجرا
--list-mirrors               نمایش لیست میرورها
--skip-test                  عدم اجرای تست hello-world
--keep-temp                  نگه داشتن پوشه موقت
--help, -h                   نمایش راهنما
```

---

## گردش‌کار پیشنهادی برای محیط Air-Gapped

1. **روی ماشین دارای اینترنت** (می‌تواند macOS یا لینوکس باشد):

   ```bash
   ./install-docker-smart.sh --distro ubuntu --codename resolute --arch amd64 --yes
   ```

2. **انتقال پوشه تولیدشده**:

   ```bash
   scp -r docker-packages/ user@airgapped-host:/opt/
   ```

3. **روی ماشین بدون اینترنت**:

   ```bash
   sudo ./install-docker-smart.sh --offline /opt/docker-packages
   ```

پوشه آفلاین شامل این موارد است:
- تمام پکیج‌های `.deb` مورد نیاز
- کلید GPG داکر
- فایل `SHA256SUMS` برای بررسی صداقت
- یک README کوچک با دستورال نصب

---

## اولویت میرورها

1. رسمی Docker (`download.docker.com`)
2. دانشگاه تسینگهوا
3. دانشگاه علوم و صنعت چین (USTC)
4. دانشگاه پکن
5. علی‌بابا
6. تنسنت کلاد
7. اروان‌کلاد
8. ایران‌سرور

برای مشاهده لیست:

```bash
./install-docker-smart.sh --list-mirrors
```

---

## بررسی صداقت

پس از دانلود، فایل `SHA256SUMS` ساخته می‌شود.

روی ماشین هدف می‌توانید قبل از نصب اعتبارسنجی کنید:

```bash
cd docker-packages
sha256sum -c SHA256SUMS
```

---

## نکات امنیتی

- اسکریپت فقط زمانی پکیج‌ها را نصب می‌کند که سیستم‌عامل واقعاً Ubuntu یا Debian-مبنا باشد.
- روی macOS و سیستم‌عامل‌های دیگر فقط عمل دانلود و آماده‌سازی بسته آفلاین را انجام می‌دهد.
- کلید GPG با روش مدرن در `/etc/apt/keyrings` نصب می‌شود.
- از `eval` روی داده‌های خارجی استفاده نمی‌شود.
- پوشه‌های موقت بهصورت پیش‌فرض پاک‌سازی می‌شوند.

---

## پیش‌نیازها

- `bash` نسخه ۳.۲ یا جدیدتر
- `curl`
- `dpkg` / `apt` (برای نصب روی ماشین هدف)
- `sha256sum` (برای بررسی صداقت پیشنهاد می‌شود)

---

## مجوز

MIT License

---

**طراحی‌شده برای نصب قابلاعتماد Docker Engine در محیط‌های محدود و Air-Gapped.**
