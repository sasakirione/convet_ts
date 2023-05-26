$logFile = "C:/path/to/logfile.log"  # ログファイルのパスを指定

$nw = Get-Date -Format o
$dt = [DateTime]$nw
$dt = $dt.AddDays(-2)
$nw = $dt.ToString("o")

$file_list = Get-ChildItem -Path 'D:/録画未整理/*.ts'
$file_list_limit_ten = $file_list[0..19]

foreach($f in $file_list_limit_ten){
    ConvertTo-MP4 -inputPath $f.FullName -targetTime $nw
}

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