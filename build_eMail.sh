#!/bin/sh

PKG_NAME="eMail"
DOWNLOAD_URL="https://github.com/deanproxy/eMail.git"
SRC_FILE="eMail.tar.gz"
SRC_FILE_MD5="git"
SRC_DIR_NAME="eMail"
DIST_FILES='email.exe,cygwin1.dll'
([ -z "$PKG_NAME" ] || [ -z "$DOWNLOAD_URL" ] || [ -z "$SRC_FILE" ] || [ -z "$SRC_DIR_NAME" ] || [ -z "$SRC_FILE_MD5" ] || [ -z "$DIST_FILES" ]) && exit


Work_Root=$(pwd)

[ "$1" = "clean" ] && rm -rf $Work_Root/srcs/${PKG_NAME}_build && exit

check_builded() {
for file in $(echo "$DIST_FILES" | tr ',' '\n'); do
	if [ ! -f $Work_Root/srcs/${PKG_NAME}_build/dist/${file} ]; then
	cat <<EOF
Build fails with ${file} no esixt!
EOF
	return 1
	else
	cat <<EOF
${file} esixt.
EOF
	fi
done
return 0
}

if check_builded; then
	cat <<EOF

run: $0 clean
EOF
exit
fi

. $Work_Root/http_proxy.conf

mkdir -p $Work_Root/dl

if [ ! -f $Work_Root/dl/$SRC_FILE ]; then
	wget "${DOWNLOAD_URL}" -O $Work_Root/dl/$SRC_FILE
	cd $Work_Root/dl/
	git clone --recursive $DOWNLOAD_URL eMail
	cd eMail
	git checkout d425405501d271d2f33ba01ada470b030c06c2b2
	cd ..
	tar czf eMail.tar.gz eMail
	rm -rf eMail/
fi


rm -rf $Work_Root/srcs/${PKG_NAME}_build
mkdir -p $Work_Root/srcs/${PKG_NAME}_build
tar zxvf $Work_Root/dl/$SRC_FILE -C $Work_Root/srcs/${PKG_NAME}_build


cd $Work_Root/srcs/${PKG_NAME}_build/${SRC_DIR_NAME}

LIBS="-ldl " LDFLAGS="-Wl,-static -static -static-libgcc " ./configure # --enable-static # --host=i686-pc-cygwin
make


# 整理文件
rm -rf $Work_Root/srcs/${PKG_NAME}_build/dist/
mkdir -p $Work_Root/srcs/${PKG_NAME}_build/dist/
cp -vr $Work_Root/srcs/${PKG_NAME}_build/${SRC_DIR_NAME}/src/*.exe $Work_Root/srcs/${PKG_NAME}_build/dist/
DLLS_NEEDS=$(for file in $(find $Work_Root/srcs/${PKG_NAME}_build/dist/ -name '*.exe'); do
	objdump -p ${file} | grep "DLL Name" | grep -v 'KERNEL32.dll'
done | awk '{print $NF}' | sort -n | uniq)
for dll_file in $DLLS_NEEDS; do
	find /bin -name ${dll_file}
done | sort -n | uniq | while read file;do
	cp -vr ${file} $Work_Root/srcs/${PKG_NAME}_build/dist/
done

check_builded

if check_builded; then
	cp -vr $Work_Root/srcs/${PKG_NAME}_build/${SRC_DIR_NAME}/src/email.exe $Work_Root/dist/eMail
fi
