<div align="center">

# 🧩 GeraKApps

### Монорепозиторий iOS-проектов экосистемы GeraK

[![iOS](https://img.shields.io/badge/platform-iOS-111827?logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)](https://www.swift.org/)
[![XcodeGen](https://img.shields.io/badge/project-XcodeGen-blue)](https://github.com/yonaskolb/XcodeGen)
[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions)](https://github.com/gkuhtov/GeraKApps/actions)

**Один репозиторий — отдельные приложения, независимые конфигурации и сборки.**

[Профиль автора](https://github.com/gkuhtov) · [Экосистема GeraK](https://github.com/gkuhtov/GeraKProtocol)

</div>

---

## 📱 Проекты

| Проект | Описание | Состояние |
|---|---|---|
| [GeraKLab](Projects/GeraKLab/README.md) | Лаборатория интерактивных экспериментов для iPhone | Существующий проект |
| [Spectra](Projects/Spectra/README.md) | Основа нового iOS-приложения для обнаружения и изучения устройств умного дома | В разработке |

Каждое приложение находится в собственной папке `Projects/<Имя>`, имеет свой `project.yml`, исходный код, ресурсы, конфигурацию и отдельный workflow сборки.

## 🧱 Структура

```text
GeraKApps/
├── Projects/
│   ├── GeraKLab/
│   │   ├── App/
│   │   ├── Core/
│   │   ├── Models/
│   │   ├── Resources/
│   │   ├── Services/
│   │   ├── Views/
│   │   └── project.yml
│   └── Spectra/
│       ├── Sources/
│       │   ├── App/
│       │   ├── Core/
│       │   ├── Domain/
│       │   ├── Data/
│       │   ├── Services/
│       │   └── Presentation/
│       ├── Resources/
│       ├── Configs/
│       ├── Tests/
│       └── project.yml
├── .github/workflows/
│   ├── build-geraklab.yml
│   ├── build-spectra.yml
│   └── validate-repository.yml
├── .gitignore
└── README.md
```

## 🛠️ Технологии и соглашения

- Swift, SwiftUI, XcodeGen и GitHub Actions.
- Текст документации и пользовательского интерфейса — на русском языке.
- Bundle ID приложений использует префикс `com.gerak`: например, `com.gerak.geraklab` и `com.gerak.spectra`.
- Конфигурации, ресурсы и секреты одного приложения не должны случайно попадать в другое.
- Каждое приложение собирается отдельно; общие workflow не должны ломать независимую сборку проектов.

## 🧰 Локальная сборка

Для сборки iOS-приложений требуется macOS с совместимой версией Xcode. Установите XcodeGen:

```bash
brew install xcodegen
```

Затем выберите приложение и перейдите в его каталог. Например, для Spectra:

```bash
cd Projects/Spectra
xcodegen generate
xcodebuild -project Spectra.xcodeproj -scheme Spectra -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Сборки в GitHub Actions запускаются отдельно для каждого проекта. Готовые артефакты публикуются в разделе Actions соответствующего workflow.

## ⚠️ Ограничения обнаружения устройств

iOS ограничивает сетевое обнаружение и работу приложений в фоне. Реально доступные устройства зависят от локальной сети, протокола, разрешений и реализации самого устройства. Spectra не обещает обнаружить абсолютно все устройства и не обходит сетевую изоляцию или механизмы безопасности.

---

## 👤 Авторство

**Гера Кухтов / madebygood** · [GitHub](https://github.com/gkuhtov)

<sub>Экосистема GeraK · Документация на русском языке</sub>
