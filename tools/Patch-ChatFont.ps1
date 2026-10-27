param([Parameter(Mandatory=$true)][string]$InputAssembly,[Parameter(Mandatory=$true)][string]$OutputAssembly,[Parameter(Mandatory=$true)][string]$CecilAssembly)
$ErrorActionPreference='Stop'
Add-Type -Path (Resolve-Path -LiteralPath $CecilAssembly)
$m=[Mono.Cecil.ModuleDefinition]::ReadModule((Resolve-Path -LiteralPath $InputAssembly).Path)
$font=$m.Types|Where-Object FullName -eq 'Assets.Scripts.GameFont';$cctor=$font.Methods|Where-Object Name -eq '.cctor';$ins=$cctor.Body.Instructions;$il=$cctor.Body.GetILProcessor()
$outerGet=($ins|Where-Object {$_.Operand -is [Mono.Cecil.MethodReference] -and $_.Operand.Name -eq 'get_Item' -and $_.Operand.DeclaringType.FullName.StartsWith('System.Collections.Generic.Dictionary`2<Assets.Scripts.Text.Language,')}|Select-Object -Last 1).Operand
$outerSet=($ins|Where-Object {$_.Operand -is [Mono.Cecil.MethodReference] -and $_.Operand.Name -eq 'set_Item' -and $_.Operand.DeclaringType.FullName.StartsWith('System.Collections.Generic.Dictionary`2<Assets.Scripts.Text.Language,')}|Select-Object -Last 1)
$add=($ins|Where-Object {$_.Operand -is [Mono.Cecil.MethodReference] -and $_.Operand.Name -eq 'set_Item' -and $_.Operand.DeclaringType.FullName.StartsWith('System.Collections.Generic.Dictionary`2<Assets.Scripts.Text.GameFontType,')}|Select-Object -First 1).Operand
$inner=$add.DeclaringType
$idict=[Mono.Cecil.TypeReference]::new('System.Collections.Generic','IDictionary`2',$m,$inner.ElementType.Scope)
$idict.GenericParameters.Add([Mono.Cecil.GenericParameter]::new('TKey',$idict));$idict.GenericParameters.Add([Mono.Cecil.GenericParameter]::new('TValue',$idict))
$ig=[Mono.Cecil.GenericInstanceType]::new($idict);foreach($p in $add.Parameters){$ig.GenericArguments.Add($p.ParameterType)}
$clone=[Mono.Cecil.MethodReference]::new('.ctor',$m.TypeSystem.Void,$inner);$clone.HasThis=$true;$clone.Parameters.Add([Mono.Cecil.ParameterDefinition]::new($ig))
$il.InsertBefore($outerSet,[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Newobj,$clone))
$innerSet=[Mono.Cecil.MethodReference]::new('set_Item',$m.TypeSystem.Void,$inner);$innerSet.HasThis=$true;foreach($p in $add.Parameters){$innerSet.Parameters.Add([Mono.Cecil.ParameterDefinition]::new($p.ParameterType))}
$load=($ins|Where-Object {$_.Operand -is [Mono.Cecil.GenericInstanceMethod] -and $_.Operand.Name -eq 'Load' -and $_.Operand.GenericArguments[0].FullName -eq 'UnityEngine.Font'}|Select-Object -First 1).Operand
$settings=($m.Types|Where-Object FullName -eq 'Assets.Scripts.FontSettings').Methods|Where-Object Name -eq '.ctor'
$fonts=$font.Fields|Where-Object Name -eq 'Fonts';$ret=$ins|Select-Object -Last 1
$seq=@(
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldsfld,$fonts),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_4),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt,$outerGet),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_3),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr,'Fonts/ChevyRay - Softsquare'),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call,$load),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_S,[sbyte]18),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Newobj,$settings),
 [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt,$innerSet)
)
foreach($i in $seq){$il.InsertBefore($ret,$i)}
$m.Write([IO.Path]::GetFullPath($OutputAssembly))
Write-Host 'Portuguese ChatText uses Softsquare 18; English and Japanese dictionaries unchanged; ProcessText untouched.'


