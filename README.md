# sport-brain-app

Личное iPhone-приложение (только TestFlight) для панели тренировок.

- Все расчёты и данные живут в закрытом репозитории `sport-brain` (GitHub Actions + задачи Claude).
- Приложение только читает `data.json`, `state/recommendation.json` и `dashboard.html` через GitHub API.
- Ключ GitHub (fine-grained, только чтение `sport-brain`, Contents: Read-only) вводится в приложении и хранится в связке ключей iPhone. В этом репозитории ключей нет.

Вкладки: Сегодня, Динамика (графики), Тренировки, Панель (та же dashboard.html), Настройки.

Сборка: проект генерируется XcodeGen из `project.yml`; workflow `build` проверяет компиляцию на macOS-машине GitHub. Выкладка в TestFlight будет добавлена после появления учётной записи Apple Developer.
