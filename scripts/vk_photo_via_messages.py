# -*- coding: utf-8 -*-
"""Эксперимент: загрузка фото через messages upload server и пост на стену.

Обход ограничения VK: photos.getWallUploadServer недоступен токену сообщества
(ошибка 27), а photos.getMessagesUploadServer — доступен. Проверяем, можно ли
фото, сохранённое через photos.saveMessagesPhoto, прикрепить к записи стены.
"""

import json
import mimetypes
import os
import sys
import urllib.parse
import urllib.request
import uuid

API = "https://api.vk.com/method/"
API_VERSION = "5.199"
CONFIG = "config/vk.secure.json"

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def call(method, token, params):
    payload = dict(params)
    payload.update({"access_token": token, "v": API_VERSION})
    data = urllib.parse.urlencode(payload).encode("utf-8")
    req = urllib.request.Request(API + method, data=data)
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.load(resp)
    if "error" in result:
        err = result["error"]
        print(f"[{method}] ERROR {err.get('error_code')}: {err.get('error_msg')}")
        return None
    print(f"[{method}] OK")
    return result["response"]


def multipart_body(field, path):
    boundary = uuid.uuid4().hex
    name = os.path.basename(path)
    mime = mimetypes.guess_type(name)[0] or "image/png"
    with open(path, "rb") as f:
        content = f.read()
    body = b"".join(
        [
            f"--{boundary}\r\n".encode(),
            f'Content-Disposition: form-data; name="{field}"; '
            f'filename="{name.encode("utf-8").decode("latin-1")}"\r\n'.encode("latin-1"),
            f"Content-Type: {mime}\r\n\r\n".encode(),
            content,
            f"\r\n--{boundary}--\r\n".encode(),
        ]
    )
    return body, f"multipart/form-data; boundary={boundary}"


def main():
    image_path = sys.argv[1]
    text_path = sys.argv[2]

    with open(CONFIG, encoding="utf-8-sig") as f:
        cfg = json.load(f)
    token = cfg["access_token"]
    group_id = int(cfg["group_id"])

    print(f"Картинка: {image_path}")
    print(f"Текст:    {text_path}")

    # 1. Сервер загрузки для сообщений (доступен токену сообщества)
    server = call("photos.getMessagesUploadServer", token, {"peer_id": group_id})
    if not server:
        server = call("photos.getMessagesUploadServer", token, {})
    if not server:
        sys.exit(1)

    # 2. Загружаем файл
    body, content_type = multipart_body("photo", image_path)
    req = urllib.request.Request(
        server["upload_url"], data=body, headers={"Content-Type": content_type}
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        uploaded = json.load(resp)
    if not uploaded.get("photo") or uploaded.get("photo") == "[]":
        print(f"[upload] ERROR сервер не принял фото: {uploaded}")
        sys.exit(1)
    print("[upload] OK")

    # 3. Сохраняем фото сообщения
    saved = call(
        "photos.saveMessagesPhoto",
        token,
        {
            "photo": uploaded["photo"],
            "server": uploaded["server"],
            "hash": uploaded["hash"],
        },
    )
    if not saved:
        sys.exit(1)
    photo = saved[0]
    attachment = f"photo{photo['owner_id']}_{photo['id']}"
    print(f"[attachment] {attachment}")

    # 4. Публикуем пост на стене с этим вложением
    with open(text_path, encoding="utf-8") as f:
        text = f.read().strip()
    posted = call(
        "wall.post",
        token,
        {
            "owner_id": -group_id,
            "from_group": 1,
            "message": text,
            "attachments": attachment,
        },
    )
    if not posted:
        sys.exit(1)
    print(f"POSTED https://vk.com/wall-{group_id}_{posted['post_id']}")


if __name__ == "__main__":
    main()
