#参考build_ios，进行简化，只保留release
#产物仓库的本地路径
PRODUCT_DIR="../FlutterProduct"
#编译得到的文件路径
BUILD_PATH=".ios/Flutter"

echo "===清理flutter历史编译==="

flutter clean

echo "===重新生成plugin索引==="

flutter packages get

if [[ $? -ne 0 ]]; then
    EchoError "Failed to install flutter plugins"
    exit -1
fi

echo "===生成App.framework 和 flutter_assets==="

flutter build ios --release

if [[ $? -ne 0 ]]; then
    EchoError "Failed to build flutter app"
    exit -1
fi

echo "===拷贝产物到FlutterProduct==="

app_plist_path="${BUILD_PATH}/AppFrameworkInfo.plist"
cp -- "${app_plist_path}" "${BUILD_PATH}/App.framework/Info.plist"
flutter_framework="${BUILD_PATH}/engine/Flutter.framework"
flutter_podspec="${BUILD_PATH}/engine/Flutter.podspec"

flutter_app="${PRODUCT_DIR}/Flutter"
mkdir -p -- "${flutter_app}"
cp -rf -- "${BUILD_PATH}/App.framework" "${flutter_app}"
cp -rf -- "${flutter_framework}" "${flutter_app}"
cp -rf -- "${flutter_podspec}" "${flutter_app}"
#sed起了什么作用？？
sed -i '' -e $'s/\'Flutter.framework\'/\'Flutter.framework\', \'App.framework\'/g' ${flutter_app}/Flutter.podspec

echo "===拷贝Plugin到FlutterProduct==="

flutter_plugin_registrant_path="${BUILD_PATH}/FlutterPluginRegistrant"
cp -rf -- "${flutter_plugin_registrant_path}" "${PRODUCT_DIR}/FlutterPluginRegistrant"
flutter_plugin=".flutter-plugins"
#OLF_IFS有什么作用？？
if [ -e $flutter_plugin ]; then
    OLD_IFS="$IFS"
    IFS="="
    cat ${flutter_plugin} | while read plugin; do
        plugin_info=($plugin)
        plugin_name=${plugin_info[0]}
        plugin_path=${plugin_info[1]}
        plugin_path_ios="${plugin_path}ios"
        cp -rf "${plugin_path_ios}" "${PRODUCT_DIR}/${plugin_name}"
    done
IFS="$OLD_IFS"
fi

echo "===上传所有产物到远程仓库==="

app_version=$(./get_version.sh)
pushd ${PRODUCT_DIR}
git add .
git commit -m "Flutter product ${app_version}"
git push
popd

echo ""
echo "done!"
exit 0


