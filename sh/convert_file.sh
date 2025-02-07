#!/bin/bash

# 检查是否提供了文件路径作为参数
if [ $# -eq 0 ]; then
    echo "请提供要处理的文件路径作为参数。"
    exit 1
fi

# 遍历所有传入的文件路径参数
for file in "$@"; do
    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo "文件 $file 不存在，跳过处理。"
        continue
    fi

    # 使用 file 命令获取文件编码
    encoding=$(file -bi "$file" | awk -F= '{print $2}')
    echo "文件 $file 的编码为: $encoding"

    # 如果编码不是 UTF-8，则进行转换
    if [ "$encoding" != "utf-8" ]; then
        echo "正在将 $file 从 $encoding 转换为 UTF-8..."
        iconv -f "$encoding" -t UTF-8 "$file" -o "$file.new"
        if [ $? -eq 0 ]; then
            mv "$file.new" "$file"
            echo "编码转换成功。"
        else
            echo "编码转换失败。"
            continue
        fi
    else
        echo "文件 $file 已经是 UTF-8 编码，跳过编码转换。"
    fi

    # 检查 dos2unix 是否安装
    if ! command -v dos2unix &> /dev/null; then
        echo "dos2unix 未安装，尝试安装..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y dos2unix
        elif command -v yum &> /dev/null; then
            sudo yum install -y dos2unix
        else
            echo "无法确定包管理器，无法安装 dos2unix，请手动安装。"
            continue
        fi
    fi

    # 使用 dos2unix 去除隐藏字符
    echo "正在去除 $file 中的隐藏字符..."
    dos2unix "$file"
    if [ $? -eq 0 ]; then
        echo "隐藏字符去除成功。"
    else
        echo "隐藏字符去除失败。"
    fi
done

echo "所有文件处理完成。"