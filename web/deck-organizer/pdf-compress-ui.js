export function download(blob,name){const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),60000);}

export async function compressAttachment(attachment, control, message, isCurrent=()=>true){
 message.textContent='';
 control.disabled=true;
 control.textContent='Opening PDF…';
 try{
  if(!confirm('Create a compressed copy with pages saved as images? Searchable text, links and interactive features will be lost in the copy. Your original will be kept.'))return;
  const {compressPdf}=await import('./compress-pdf.js');
  const result=await compressPdf(attachment.blob,(page,total)=>{
   if(!isCurrent())throw new Error('Compression cancelled.');
   control.textContent=`Compressing ${page}/${total}…`;
  });
  if(!isCurrent())return;
  if(result.size>=attachment.blob.size){
   message.textContent='This PDF could not be made smaller.';
   return;
  }
  const kb=bytes=>`${Math.round(bytes/1024).toLocaleString()} KB`;
  if(confirm(`PDF size: ${kb(attachment.blob.size)} → ${kb(result.size)}. Download the compressed copy?`)){
   download(result,`${attachment.name.replace(/\.pdf$/i,'')}-compressed.pdf`);
  }
 }catch(e){
  if(isCurrent())message.textContent=e.message||'Could not compress this PDF.';
 }finally{
  control.disabled=false;
  control.textContent='Compress PDF';
 }
}
