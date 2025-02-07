#!/bin/bash
SRC_DIR="/root/workspace"
DEST_DIR="/root/MHCB12/vendor/xiaomi/mijia_ble_mesh"
EVENTS="create,delete,modify,move"

# 检查源目录是否存在
if [ ! -d "$SRC_DIR" ]; then
    echo "Source directory $SRC_DIR does not exist."
    exit 1
fi

# 检查目标目录是否存在，如果不存在则创建
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create destination directory $DEST_DIR."
        exit 1
    fi
fi

# 检查源目录和目标目录的读写权限
if [ ! -r "$SRC_DIR" ] || [ ! -w "$SRC_DIR" ]; then
    echo "No read or write permission on source directory $SRC_DIR."
    exit 1
fi

if [ ! -w "$DEST_DIR" ]; then
    echo "No write permission on destination directory $DEST_DIR."
    exit 1
fi

# 第一次启动时进行同步
rsync -avz --delete "$SRC_DIR/" "$DEST_DIR/"
if [ $? -ne 0 ]; then
    echo "Initial rsync failed."
fi

# 监控目录变化并执行同步操作
inotifywait -m -r -e $EVENTS $SRC_DIR | while read path action file; do
    rsync -avz --delete "$SRC_DIR/" "$DEST_DIR/"
    if [ $? -ne 0 ]; then
        echo "Rsync failed during synchronization."
    fi
done