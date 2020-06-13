// Async await and Timer class
import 'dart:async';

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

import "database.dart";

void main() async {
  // Garantindo que o DB vai ser seedado antes
  WidgetsFlutterBinding.ensureInitialized();
  // Seedando o banco de dados
  await TrackerDatabase.seedDatabase();
  // Rodando o app
  runApp(MyApp());
}

class ActivityForm extends StatelessWidget {
  ActivityForm({Key key, this.activitySwitcher, this.activities, @required this.signalSwitch})
      : super(key: key);

  final Map<int, bool> activitySwitcher;
  final List<Activity> activities;
  final ValueChanged<Activity> signalSwitch;

  void _handleSwitchPress(Activity activity) { signalSwitch(activity); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        itemBuilder: (context, i) {
          return Container(
              padding: EdgeInsets.only(left: 8, right: 8),
              child: OutlineButton(
                textColor: activitySwitcher[activities[i].id] ? Colors.orange : Colors.grey,
                // color: activitySwitcher[activities[i].id] ? Colors.orange : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Text(
                  activities[i].name,
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.35,
                ),
                onPressed: () {_handleSwitchPress(activities[i]);},
              ));
        });
  }
}

// Timer text that show counted time
class TrackerTimer extends StatelessWidget {
  TrackerTimer({Key key, this.stopwatch, this.value, @required this.tick})
      : super(key: key);

  final Stopwatch stopwatch;
  final String value;
  final ValueChanged<bool> tick;

  void _handleTick() {
    tick(false);
  }

  @override
  Widget build(BuildContext context) {
    Timer timeUpdater = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _handleTick();
    });
    if (!stopwatch.isRunning) timeUpdater.cancel();

    return Text(
      value,
      style: TextStyle(fontSize: 50.0),
    );
  }
}

// Button that starts timer
class Button extends StatelessWidget {
  Button({Key key, this.counting: false, @required this.onChanged})
      : super(key: key);

  final bool counting;
  final ValueChanged<bool> onChanged;

  static double _buttonSize = 200;

  void _handleTap() {
    onChanged(!counting);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Ink(
        decoration: ShapeDecoration(
            shape: CircleBorder(), color: counting ? Colors.red : Colors.blue),
        child: SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: IconButton(
            iconSize: _buttonSize / 2,
            icon: counting
                ? Icon(Icons.close)
                : Icon(Icons.radio_button_unchecked),
            onPressed: _handleTap,
          ),
        ),
      ),
    );
  }
}

// This widget controls all children
class _RootState extends State<Root> {
  // Button related states
  bool _counting = false;

  // Timer related states
  Stopwatch _watch = Stopwatch();
  String _timeElapsedValue = Stopwatch().elapsed.toString().substring(0, 7);

  // ActivityForm related states
  Map<int, bool> _activitySwitches = Map<int, bool>();
  List<Activity> _toggledActivities = List<Activity>();

  // I wanted to print the counted values, but _activitySwitches only allows me to get it's ID, so this is wonky now
  void _toggleActivity(Activity activity) {
    setState(() {
      // Setting List to have item
      if(_toggledActivities.isNotEmpty){
        if(!_toggledActivities.contains(activity)){
          _toggledActivities.add(activity);
        } else {
          _toggledActivities.remove(activity);
        }
      } else _toggledActivities.add(activity);

      _activitySwitches[activity.id] = !_activitySwitches[activity.id];
    });
    
    // Should print boolean
  }

  void _updateTimerValues(bool value) {
    if (_counting || value) {
      setState(() {
        _timeElapsedValue = _watch.elapsed
            .toString()
            .substring(0, _watch.elapsed.toString().length - 7);
      });
    }
  }

  void _toggleTimer(bool value) {
    setState(() {
      _counting = value;
      // Here I'd start counting and periodically update child
      if (_counting) {
        _watch.start();
        // Down here I'd stop the timer, reset it and save the elapsed time
      } else {
        // print(_watch.elapsed.toString());
        for (Activity activity in _toggledActivities) {
          print("You did " + _watch.elapsed.toString() + " on activity " + activity.name);
        }
        _watch.reset();
        _watch.stop();
        _updateTimerValues(true);
      }
      print(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
            padding: EdgeInsets.only(top: 100),
            child: TrackerTimer(
                stopwatch: _watch,
                value: _timeElapsedValue,
                tick: _updateTimerValues)),
        Container(
            padding: EdgeInsets.only(top: 100),
            child: Button(
              counting: _counting,
              onChanged: _toggleTimer,
            )),
        FutureBuilder(
          future: TrackerDatabase.activities(),
          builder: (BuildContext context, AsyncSnapshot<List<Activity>> snapshot) {
            if (snapshot.hasData) {
              print(_activitySwitches);
              if (_activitySwitches.isEmpty){
                for(Activity activity in snapshot.data) {
                  _activitySwitches[activity.id] = false;
                }
              }
              return Container(
                  padding: EdgeInsets.only(top: 50),
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 24,
                    child: ActivityForm(
                      activitySwitcher: _activitySwitches,
                      activities: snapshot.data,
                      signalSwitch: _toggleActivity,
                    ),
                  ));
            } else return Container();
          },
        ),
      ],
    );
  }
}

class Root extends StatefulWidget {
  @override
  _RootState createState() => _RootState();
}

// Sets MaterialApp, with Column Widget that receives Root as children container
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Root()),
      ),
    );
  }
}
