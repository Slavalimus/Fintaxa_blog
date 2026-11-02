# 🔐 Конфигурация FinTaxa

Здесь лежат настройки платформ публикации.

## Файлы в репозитории (публичные)

- `telegram.example.json` — шаблон конфигурации Telegram-бота
- `vk.example.json` — шаблон конфигурации сообщества VK

## Локальные файлы (НЕ коммитятся, см. `.gitignore`)

- `telegram.secure.json` — токен бота Telegram
- `vk.secure.json` — токен сообщества VK
- `vk_app.secure.json` — данные приложения VK (OAuth)
- `vk_user_token.json` — пользовательский токен VK
- `vk_oauth_state.json` — состояние OAuth-авторизации VK

## Как настроить

1. Скопируйте шаблон: `telegram.example.json` → `telegram.secure.json`
2. Вставьте свои токены
3. Проверьте, что `.gitignore` исключает `*.secure.json` — **перед первым
   коммитом** убедитесь, что секретные файлы не попали в индекс git!
