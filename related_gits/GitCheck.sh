#!/bin/bash

set -e

print() {
    echo -e "\033[91m$1\033[0m"
}
print_red() {
    echo -e "\033[1;91m$1\033[0m"
}
print_green() {
    echo -e "\033[92m$1\033[0m"
}

git_clone() {
    path=$1
    name=`basename $1`
    git clone https://github.com/iozxvz/$path.git . \
    || (print_red "error: 找不到 $name 仓库" >&2; exit 1)
}

git_fetch() {
    path=$1
    branch=$2
    git fetch https://github.com/iozxvz/$path.git $branch
}

git_pull() {
    path=$1
    branch=$2
    git pull --ff-only https://github.com/iozxvz/$path.git $branch
}

export LC_ALL="en_US.UTF-8"
build_type=$1

# 相关依赖仓库目录
dir="`pwd`/cc_shared"
uncommit=""

# 检查仓库是否对应
check() {
    path=$1 # 仓库路径
    name=`basename $1` # 仓库名称
    branch=$2 # 分支名
    sha=$3 # 提交

    # 如果不存在依赖仓库目录，则创建
    if [ ! -d "$dir" ]; then
        mkdir $dir
    fi
    # 如果找不到目录，则创建
    if [ ! -d "$dir/$name" ]; then
        mkdir $dir/$name
    fi

    # 切换到指定仓库目录下
    cd $dir/$name

    # 进行 git 相关操作
    git_operations

    # 如果存在未提交变动，提醒开发者，防止遗漏提交基础库中的代码
    if [ -n "$(git status --porcelain)" ]; then
        uncommit="${uncommit}\nwarning: $name: 存在未提交的变动❗️"
        if [[ $build_type == "cmd_build" ]] && [[ $name != "TestGround" ]]; then
            echo $uncommit
            exit 1
        fi
    fi
}

# git 相关操作
git_operations() {
    echo -e "\033[1m[ $name ]\033[0m"
    # 如果没有 git，尝试拉取
    if [ ! -d .git ]; then
        print "$name 本地仓库不存在，开始拉取"
        git_clone $path
    fi

    # 如果未指定提交或当前提交和指定提交不符，尝试切换到指定提交
    cur_sha=`git rev-parse HEAD`
    if [ "$cur_sha" != "$sha" ]; then
        # 先尝试拉取分支
        git_fetch $path $branch
        print "$name 切换到 $branch 分支 (git checkout)"
        git checkout $branch || git checkout -b $branch origin/$branch
        print "$name 拉取 $branch 分支 (git pull)"
        git_pull $path $branch
        # 如果存在指定提交，再切换到指定提交
        if [ -n "$sha" ]; then
            cur_sha=`git rev-parse HEAD`
            if [ "$cur_sha" != "$sha" ]; then
                print_red "$name checkout detached Head"
                git -c advice.detachedHead=false checkout $sha \
                || (print_red "error: $name 没有找到指定的 SHA $sha" >&2; exit 1)
            fi
        fi
    else
        print_green "$name 已经在指定位置"
    fi

    # 如果有 GitRun 脚本且可执行，则执行它
    if [ -x "./GitRun.sh" ]; then
        print "> 执行 GitRun 脚本 ($name)"
        ./GitRun.sh
    fi
}

# 读取每行，分割参数，调用检查方法（仓库名称:分支名:提交）
for line in $(cat GitLock.txt)
do
    if [[ $line == \#* ]]; then
        continue
    fi
    check `echo $line | cut -d ":" -f 1` `echo $line | cut -d ":" -f 2` `echo $line | cut -d ":" -f 3`
done
