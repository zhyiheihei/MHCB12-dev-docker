#!/bin/bash
###
 # @Author       : error: git config user.name & please set dead value or install git
 # @Date         : 2025-02-08 02:42:01
 # @LastEditors  : moli-pp
 # @LastEditTime : 2025-02-08 05:55:33
 # @FilePath     : \MHCB12-dev-docker\sh\build.sh
 # @Description  : 
 # 
 # Copyright (c) 2025 by lym, All Rights Reserved. 
### 

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
else
    echo "不支持的参数: $1，仅支持 'clean' 参数或者不传参数。"
    exit 1
fi

# 执行编译命令，并在后台运行
$BUILD_COMMAND &
BUILD_PID=$!

# 定义要检查的文件目录
CHECK_DIR="/root/MHCB12/vendor/realtek/tools/bee/application_is/Debug/bin/"

# 循环检查编译命令是否还在运行
while ps -p $BUILD_PID > /dev/null
do
    # 检查是否存在满足条件的文件
    if find "$CHECK_DIR" -maxdepth 1 -name "application_is_MP_*" | grep -q .; then
        $MOVE_COMMAND
        if [ $? -ne 0 ]; then
            echo "文件移动失败，退出状态码: $?"
        fi
    fi
    sleep 5  # 每5秒检查一次
done

# 等待编译命令完成
wait $BUILD_PID

# 检查编译命令的退出状态
if [ $? -eq 0 ]; then
    if [ "$1" != "clean" ]; then
        # 再次检查并移动文件，确保最后一次检查
        if find "$CHECK_DIR" -maxdepth 1 -name "application_is_MP_*" | grep -q .; then
            $MOVE_COMMAND
            if [ $? -ne 0 ]; then
                echo "文件移动失败，退出状态码: $?"
            fi
        fi

        # 执行 convert_file.sh 脚本
        /root/convert_file.sh /root/MHCB12/vendor/xiaomi/mijia_ble_mesh/Kconfig
        if [ $? -ne 0 ]; then
            echo "convert_file.sh 脚本执行失败，退出状态码: $?"
        fi

        # 退出后续检查流程
        exit 0
    else
        echo "清理编译成功。"
    fi
else
    echo "编译或清理操作失败，退出状态码: $?，跳过文件移动步骤。"
fi