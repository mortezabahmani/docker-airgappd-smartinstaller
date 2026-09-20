# نصب‌کننده هوشمند Docker برای محیط‌های بدون اینترنت (Air-Gapped)

**ابزار هوشمند نصب Docker Engine** با پشتیبانی از چندین میرور و قابلیت نصب کاملاً آفلاین، مخصوصاً برای محیط‌های جداشانده از شبکه و مناطق دارای محدودیت شبکه‌ای.

[![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)](CHANGELOG.md)

> 📖 English documentation → [README.md](README.md)

---

## قابلیت‌ها

| قابلیت | توضیح |
|---------|-------------|
| **دو حالته کاری** | دانلود آنلاین با Fallback + نصب خالص آفلاین |
| **غیرتعاملی** | `--distro`، `--codename`، `--arch`، `--yes` |
| **صداقت‌سنجی** | تولید و بررسی `SHA256SUMS` |
| **معماری** | پیش‌فرض `amd64`؛ `arm64` فقط با انتخاب صریح |
| **توزیع‌ها** | Ubuntu (resolute, noble) و Debian (trixie, bookworm) |
| **پراکسی** | `http_proxy` / `https_proxy` |
| **Dry-Run** | `--dry-run` |
| **تست پس از نصب** | `hello-world` (اختیاری) |

---

## شروع سریع

```bash
chmod +x install-docker-smart.sh
./install-docker-smart.sh
```

### نمونه غیرتعاملی

```bash
./install-docker-smart.sh \
  --distro ubuntu \
  --codename resolute \
  --arch amd64 \
  --yes
```

### نصب آفلاین

```bash
sudo ./install-docker-smart.sh --offline /path/to/docker-packages
```

---

## گردش‌کار Air-Gapped

1. روی ماشین دارای اینترنت پکیج‌ها را دانلود کنید.
2. پوشه `docker-packages/` را به ماشین هدف منتقل کنید.
3. روی ماشین بدون اینترنت با `--offline` نصب کنید.

> **توجه:** پوشه‌های `docker-packages/` و `docker-offline-*/` را در git کامیت نکنید. در `.gitignore` هستند.

---

## تاریخچه تغییرات

جزئیات نسخه‌ها و تغییرات در [CHANGELOG.md](CHANGELOG.md) ثبت می‌شود.

---

## مجوز

MIT License

---

**طراحی‌شده برای نصب قابلاعتماد Docker در محیط‌های محدود و Air-Gapped.**
