using System;
using System.Linq;
using Mono.Cecil;
using Mono.Cecil.Cil;
class PatchLanguage {
 static void Require(bool b,string s){if(!b)throw new Exception(s);}
 static void Insert(ILProcessor il,Instruction before,params Instruction[] seq){foreach(var i in seq)il.InsertBefore(before,i);}
 static TypeDefinition Type(ModuleDefinition m,string name){var t=m.Types.SingleOrDefault(x=>x.FullName==name);Require(t!=null,"Missing type "+name);return t;}
 static void Main(string[] args) {
  using(var m=ModuleDefinition.ReadModule(args[0])){
   var lang=Type(m,"Assets.Scripts.Text.Language");
   Require(!lang.Fields.Any(f=>f.Name=="Portuguese"),"Already patched; restore the original backup first");
   Require(lang.Fields.Single(f=>f.Name=="English").Constant.Equals(2)&&lang.Fields.Single(f=>f.Name=="Japanese").Constant.Equals(3),"Unknown language IDs");
   var pt=new FieldDefinition("Portuguese",FieldAttributes.Public|FieldAttributes.Static|FieldAttributes.Literal|FieldAttributes.HasDefault,lang){Constant=4};
   var en=lang.Fields.Single(f=>f.Name=="English");
   foreach(var ca in en.CustomAttributes.Where(a=>a.AttributeType.Name=="DescriptionAttribute")){
    var a=new CustomAttribute(ca.Constructor);a.ConstructorArguments.Add(new CustomAttributeArgument(m.TypeSystem.String,"Portugues (Brasil)"));pt.CustomAttributes.Add(a);
   }
   lang.Fields.Add(pt);
   var init=Type(m,"Assets.Scripts.Text.Localization").Methods.Single(x=>x.Name=="Initialize");
   var limit=init.Body.Instructions.Where(i=>i.OpCode==OpCodes.Ldc_I4_3 && i.Next.OpCode==OpCodes.Stloc_2).ToArray();
   Require(limit.Length==1,"Unknown localization parser");limit[0].OpCode=OpCodes.Ldc_I4_4;
   var menu=Type(m,"Assets.Scripts.UI.Menus.SettingsMenu").Methods.Single(x=>x.Name=="CreateGeneralPage");
   var arr=menu.Body.Instructions.Single(i=>i.OpCode==OpCodes.Newarr && i.Operand.ToString().Contains("UsableOption") && i.Operand.ToString().Contains("Text.Language"));
   Require(arr.Previous.OpCode==OpCodes.Ldc_I4_2,"Unknown language menu");
   arr.Previous.OpCode=OpCodes.Ldc_I4_3;
   var jp=menu.Body.Instructions.Single(i=>i.OpCode==OpCodes.Ldstr && (string)i.Operand=="Japanese");
   Require(jp.Next.OpCode==OpCodes.Newobj&&jp.Next.Next.OpCode==OpCodes.Stelem_Ref,"Unknown menu option");
   Insert(menu.Body.GetILProcessor(),jp.Next.Next.Next,
    Instruction.Create(OpCodes.Dup),Instruction.Create(OpCodes.Ldc_I4_2),Instruction.Create(OpCodes.Ldc_I4_4),
    Instruction.Create(OpCodes.Ldc_I4_0),Instruction.Create(OpCodes.Ldstr,"Portugues (Brasil)"),
    Instruction.Create(OpCodes.Newobj,(MethodReference)jp.Next.Operand),Instruction.Create(OpCodes.Stelem_Ref));
   var font=Type(m,"Assets.Scripts.GameFont");var cctor=font.Methods.Single(x=>x.Name==".cctor");
   var ins=cctor.Body.Instructions;var il=cctor.Body.GetILProcessor();
   var refs=ins.Select(i=>i.Operand).OfType<MethodReference>().ToArray();
   var outerGet=refs.First(x=>x.Name=="get_Item"&&x.DeclaringType.FullName.StartsWith("System.Collections.Generic.Dictionary\u00602<Assets.Scripts.Text.Language,"));
   var outerSet=refs.First(x=>x.Name=="set_Item"&&x.DeclaringType.FullName==outerGet.DeclaringType.FullName);
   var innerSet=refs.First(x=>x.Name=="set_Item"&&x.DeclaringType.FullName.StartsWith("System.Collections.Generic.Dictionary\u00602<Assets.Scripts.Text.GameFontType,"));
   var inner=innerSet.DeclaringType;
   var idict=new TypeReference("System.Collections.Generic","IDictionary\u00602",m,inner.Scope);
   idict.GenericParameters.Add(new GenericParameter("TKey",idict));idict.GenericParameters.Add(new GenericParameter("TValue",idict));
   var ig=new GenericInstanceType(idict);foreach(var p in innerSet.Parameters)ig.GenericArguments.Add(p.ParameterType);
   var clone=new MethodReference(".ctor",m.TypeSystem.Void,inner){HasThis=true};clone.Parameters.Add(new ParameterDefinition(ig));
   var fonts=font.Fields.Single(f=>f.Name=="Fonts");
   var load=refs.OfType<GenericInstanceMethod>().First(x=>x.Name=="Load"&&x.GenericArguments[0].FullName=="UnityEngine.Font");
   var settings=Type(m,"Assets.Scripts.FontSettings").Methods.Single(x=>x.Name==".ctor");
   Require(ins.Last().OpCode==OpCodes.Ret,"Unknown font initializer");
   Insert(il,ins.Last(),
    Instruction.Create(OpCodes.Ldsfld,fonts),Instruction.Create(OpCodes.Ldc_I4_4),
    Instruction.Create(OpCodes.Ldsfld,fonts),Instruction.Create(OpCodes.Ldc_I4_2),Instruction.Create(OpCodes.Callvirt,outerGet),
    Instruction.Create(OpCodes.Newobj,clone),Instruction.Create(OpCodes.Callvirt,outerSet),
    Instruction.Create(OpCodes.Ldsfld,fonts),Instruction.Create(OpCodes.Ldc_I4_4),Instruction.Create(OpCodes.Callvirt,outerGet),
    Instruction.Create(OpCodes.Ldc_I4_3),Instruction.Create(OpCodes.Ldstr,"Fonts/ChevyRay - Softsquare"),
    Instruction.Create(OpCodes.Call,load),Instruction.Create(OpCodes.Ldc_I4_S,(sbyte)18),Instruction.Create(OpCodes.Ldc_I4_0),
    Instruction.Create(OpCodes.Newobj,settings),Instruction.Create(OpCodes.Callvirt,innerSet));
   // Expanding short branches prevents overflow after added menu instructions.
   foreach(var method in new[]{init,menu,cctor})foreach(var i in method.Body.Instructions){
    if(i.OpCode.OperandType==OperandType.ShortInlineBrTarget){
     var field=typeof(OpCodes).GetFields().Single(f=>f.FieldType==typeof(OpCode)&&((OpCode)f.GetValue(null)).Name==i.OpCode.Name.Substring(0,i.OpCode.Name.Length-2));
     i.OpCode=(OpCode)field.GetValue(null);
    }
   }
   m.Write(args[1]);
   Console.WriteLine("PASS: added Portuguese and its proportional font; existing methods outside localization/menu/font initialization preserved.");
  }
 }
}
