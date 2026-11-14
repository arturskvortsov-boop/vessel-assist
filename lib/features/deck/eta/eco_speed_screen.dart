import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../domain/models/eta_model.dart';
import '../../../domain/models/eco_speed_model.dart';

class EcoSpeedScreen extends StatefulWidget {
  const EcoSpeedScreen({super.key});
  @override
  State<EcoSpeedScreen> createState()=>_EcoSpeedScreenState();
}
class _EcoSpeedScreenState extends State<EcoSpeedScreen> {
  final _form=GlobalKey<FormState>();
  final _distance=TextEditingController(),_eco=TextEditingController(),_full=TextEditingController();
  late DateTime _departure,_arrival;
  EcoSpeedPlan? _result;
  String? _error;
  @override
  void initState(){super.initState();final n=DateTime.now().toUtc();_departure=DateTime.utc(n.year,n.month,n.day,n.hour,n.minute);_arrival=_departure.add(const Duration(days:1));}
  @override
  void dispose(){_distance.dispose();_eco.dispose();_full.dispose();super.dispose();}
  double? number(String s){final n=double.tryParse(s.trim().replaceAll(',','.'));return n!=null&&n.isFinite?n:null;}
  void invalidate(){_result=null;_error=null;}
  Future<void> pick(bool departure) async {
    final old=departure?_departure:_arrival;
    final date=await showDatePicker(context:context,initialDate:DateTime(old.year,old.month,old.day),firstDate:DateTime(2000),lastDate:DateTime(2100,12,31));
    if(date==null||!mounted)return;
    final time=await showTimePicker(context:context,initialTime:TimeOfDay(hour:old.hour,minute:old.minute),builder:(c,w)=>MediaQuery(data:MediaQuery.of(c).copyWith(alwaysUse24HourFormat:true),child:w!));
    if(time==null||!mounted)return;
    setState((){final value=DateTime.utc(date.year,date.month,date.day,time.hour,time.minute);if(departure){_departure=value;}else{_arrival=value;}invalidate();});
  }
  Widget field(TextEditingController c,String label)=>Padding(padding:const EdgeInsets.only(bottom:18),child:TextFormField(controller:c,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder(),filled:true,fillColor:cardSolid),keyboardType:const TextInputType.numberWithOptions(decimal:true),onChanged:(_)=>setState(invalidate),validator:(s)=>number(s??'')==null||number(s??'')!<=0?'Enter a positive number.':null));
  void calculate(){if(!_form.currentState!.validate())return;try{final r=EcoSpeedPlan.calculate(distance:number(_distance.text)!,ecoSpeed:number(_eco.text)!,fullSpeed:number(_full.text)!,departure:_departure,arrival:_arrival);setState((){_result=r;_error=null;});}on FormatException catch(e){setState((){_result=null;_error=e.message;});}}
  Widget modeResult(String title,double hours,double distance)=>GlassCard(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:accent,fontSize:22,fontWeight:FontWeight.bold)),SizedBox(height:10),Text('${hours.toStringAsFixed(4)} hours'),Text('${(hours/24).toStringAsFixed(4)} days'),Text(etaDuration(Duration(microseconds:(hours*3600000000).round()))),SizedBox(height:8),Text('${distance.toStringAsFixed(2)} NM')])));
  @override
  Widget build(BuildContext context)=>AppScaffold(title:'Eco / Full Speed',body:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('Plan how long to sail at Eco Speed and Full Speed to cover the remaining distance and arrive at the target time.',style:TextStyle(fontSize:18,height:1.5)),
    const SizedBox(height:10),const Text('Enter average speeds over ground (SOG). All dates and times below are UTC. Stops and waiting time are not included.',style:TextStyle(color:textMuted,height:1.5)),const SizedBox(height:24),
        Form(key:_form,child:Column(children:[field(_distance,'Distance / Remaining Distance (NM)'),field(_eco,'Eco Speed (kts)'),field(_full,'Full Speed (kts)')])),
    _DateTimeField(
      label: 'Departure Time (UTC)',
      value: _departure,
      icon: Icons.flight_takeoff,
      onTap: () => pick(true),
      onNow: () {
        final n = DateTime.now().toUtc();
        setState(() {
          _departure = DateTime.utc(n.year, n.month, n.day, n.hour, n.minute);
          invalidate();
        });
      },
    ),
    const SizedBox(height: 14),
    _DateTimeField(
      label: 'Target Arrival (UTC)',
      value: _arrival,
      icon: Icons.flight_land,
      onTap: () => pick(false),
    ),
    const SizedBox(height:14),Text('Available time: ${(_arrival.difference(_departure).inMinutes/60).toStringAsFixed(2)} hours'),const SizedBox(height:20),
    FilledButton(onPressed:calculate,child:const Padding(padding:EdgeInsets.all(16),child:Text('Calculate Eco / Full Speed'))),
    if(_error!=null)Padding(padding:const EdgeInsets.only(top:18),child:Text(_error!,style:const TextStyle(color:Colors.amber,height:1.5))),
    if(_result!=null)...[modeResult('Eco Speed',_result!.ecoHours,_result!.ecoDistance),const SizedBox(height: 12),modeResult('Full Speed',_result!.fullHours,_result!.fullDistance),const SizedBox(height:18),Text('Total: ${_result!.totalHours.toStringAsFixed(4)} hours / ${(_result!.totalHours/24).toStringAsFixed(4)} days'),Text('Target arrival: ${etaDateTime(_arrival)} UTC'),const SizedBox(height:12),const Text('The result gives the total time in each mode. It does not prescribe which mode to use first.',style:TextStyle(color:textMuted,height:1.5))],
  ])))));
}

/// Аккуратное поле даты/времени: иконка, подпись и значение в одну карточку.
class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onNow;
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: textMuted, fontSize: 12, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(
                        etaDateTime(value),
                        style: const TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (onNow != null)
                  IconButton(
                    tooltip: 'Use current time',
                    onPressed: onNow,
                    icon: Icon(Icons.schedule, color: accent, size: 20),
                  ),
                Icon(Icons.edit_calendar_outlined, color: textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
