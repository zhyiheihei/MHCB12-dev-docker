#!/bin/bash
###
 # @Author       : error: git config user.name & please set dead value or install git
 # @Date         : 2025-02-08 02:42:01
 # @LastEditors  : moli-pp
 # @LastEditTime : 2025-04-11 14:18:41
 # @FilePath     : \MHCB12-dev-docker\sh\build.sh
 # @Description  : 
 # 
 # Copyright (c) 2025 by lym, All Rights Reserved. 
### 

# 清空目标目录并同步workspace数据，忽略隐藏文件夹
SYNC_COMMAND="rsync -avz --delete --exclude='.*/' --exclude='.*' /root/workspace/ /root/MHCB12/vendor/xiaomi/mijia_ble_mesh/ && find /root/MHCB12/vendor/xiaomi/mijia_ble_mesh/ -type f -exec dos2unix {} \;"

# 执行同步和行尾转换
if [ "$1" != "clean" ]; then

    echo "正在同步workspace数据并转换行尾..."
    eval $SYNC_COMMAND
    if [ $? -ne 0 ]; then
        echo "同步和行尾转换失败，退出状态码: $?"
        exit 1
    fi
    echo "同步和行尾转换完成。"
fi

# 定义进入目录命令
CD_COMMAND="cd /root/MHCB12"
# 定义文件移动命令
MOVE_COMMAND="rsync -avz --remove-source-files --include=application_is_MP_* --exclude=* /root/MHCB12/vendor/realtek/tools/bee/application_is/Debug/bin/ /root/workspace/output/"

# 执行进入目录命令
eval $CD_COMMAND

# 检查进入目录命令的退出状态
if [ $? -ne 0 ]; then
    echo "进入目录失败，退出状态码: $?，跳过后续步骤。"
    exit 1
fi

# 处理参数
if [ $# -eq 0 ]; then
    # 没有传参数，执行正常编译命令
    BUILD_COMMAND="./build.sh vendor/realtek/boards/rtl8762e/configs/app"
elif [ "$1" = "clean" ]; then
    # 传入参数为 clean，执行清理编译命令
    BUILD_COMMAND="./build.sh vendor/realtek/boards/rtl8762e/configs/app distclean"
elif [ "$1" = "menuconfig" ]; then
    # 传入参数为 menuconfig，执行清理编译命令
    BUILD_COMMAND="./build.sh vendor/realtek/boards/rtl8762e/configs/app menuconfig"
elif [ "$1" = "pm" ]; then
    # 传入参数为 pm，执行清理编译命令
    BUILD_COMMAND="./build.sh vendor/realtek/boards/rtl8762e/configs/app_pm"
else
    echo "不支持的参数: $1，仅支持 'clean' 参数或者不传参数。"
    exit 1
fi

# 确保输出目录存在
mkdir -p /root/workspace/output/

# 执行编译命令，并在后台运行
echo "开始执行构建命令: $BUILD_COMMAND"
$BUILD_COMMAND &
BUILD_PID=$!

# 定义要检查的文件目录
CHECK_DIR="/root/MHCB12/vendor/realtek/tools/bee/application_is/Debug/bin/"

# 循环检查编译命令是否还在运行
while ps -p $BUILD_PID > /dev/null
do
    # 检查是否存在满足条件的文件
    if find "$CHECK_DIR" -maxdepth 1 -name "application_is_MP_*" | grep -q .; then
        echo "检测到新生成的文件，正在移动..."
        $MOVE_COMMAND
        if [ $? -ne 0 ]; then
            echo "文件移动失败，退出状态码: $?"
        else
            echo "文件已成功移动到workspace/output目录"
        fi
    fi
    sleep 5  # 每5秒检查一次
done

# 等待编译命令完成
wait $BUILD_PID
BUILD_EXIT_CODE=$?

# 检查编译命令的退出状态
if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "编译成功完成。"
    if [ "$1" != "clean" ]; then
        # 再次检查并移动文件，确保最后一次检查
        if find "$CHECK_DIR" -maxdepth 1 -name "application_is_MP_*" | grep -q .; then
            echo "检测到最终生成的文件，正在移动..."
            $MOVE_COMMAND
            if [ $? -ne 0 ]; then
                echo "文件移动失败，退出状态码: $?"
            else
                echo "文件已成功移动到workspace/output目录"
            fi
        fi
        echo "所有操作已完成"
        # 退出后续检查流程
        exit 0
    else
        echo "清理编译成功。"
    fi
else
    echo "编译或清理操作失败，退出状态码: $BUILD_EXIT_CODE，跳过文件移动步骤。"
    exit $BUILD_EXIT_CODE
fi