$logFile = "../log/logfile.log"  # ログファイルのパスを指定

$nw = Get-Date -Format o
$dt = [DateTime]$nw
$dt = $dt.AddDays(-2)
$nw = $dt.ToString("o")

WriteLog -message "処理開始"

# yaml設定ファイルを読み込む
$yaml = Get-Content -Path "../config/config.yaml" | ConvertFrom-Yaml
$source_path = $yaml.source_path + "*.ts"
$process_count = $yaml.process_count

# 対象ファイル一覧を取得する
$file_list = Get-ChildItem -Path $source_path
$file_list_count = $file_list.Count

# 対象ファイルが多すぎる場合に規定の数に絞る
# 対象がない場合
$target_file_list = @()
if ($file_list_count -eq 0){
    WriteLog -message "処理対象のファイルがありません"
    exit
# 対象が20個以下の場合
} elseif ($file_list_count -le $process_count){
    $target_file_list = $file_list 
} else {
    $index = $process_count - 1
    $target_file_list = $file_list[0..$index]
}

foreach($f in $target_file_list){
    ConvertTo-MP4 -inputPath $f.FullName -targetTime $nw
}
WriteLog -message "処理終了"


function WriteLog($message){
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $global:logFile -Value $logMessage
}

function ConvertTo-MP4($inputPath, $targetTime){
    $fileInfo = Get-ItemProperty -Path $inputPath
    $fileTimeStamp = $fileInfo.LastWriteTime.ToString("o")

    if ($fileTimeStamp -ge $targetTime){
        return
    }
    
    $inputPath = $inputPath -replace "\\", "/"
    $output_path = [IO.Path]::ChangeExtension($inputPath, '.mp4')

    $cmd = @()
    $cmd += 'C:/Users/Public/ffmpeg.exe'
    $cmd += "-i"
    $cmd += "`"$inputPath`""
    $cmd += "-vf"
    $cmd += 'scale=1280:-1'
    $cmd += "-q:v"
    $cmd += "22"
    $cmd += "`"$output_path`""
    
    WriteLog -message "$cmd"

    try {
        $process = Start-Process -FilePath $cmd[0] -ArgumentList ($cmd[1..($cmd.Count -1)]) -Wait -PassThru -NoNewWindow
        $return_code = $process.ExitCode

        if ($return_code -eq 0){
            WriteLog -message "$inputPath - 成功"
            Remove-Item -Path $inputPath
            Remove-Item -Path "$($inputPath).err"
            Remove-Item -Path "$($inputPath).program.txt"
        } else {
            WriteLog -message "$inputPath - 失敗"
        }
    } catch {
        WriteLog -message "$inputPath - 失敗"
    }
}