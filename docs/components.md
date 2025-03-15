
## DesignSystemSetup

Components use common design system properties. The components have a local variable `designSystem` that can be passed via the View Model.


## ClarifyEvidenceControl

Depending on variables in RecordedThingViewModel a SimpleConfirmDenyStatement will be shown.
If nothing is shown a given height is maintained.
If evidenceOptions: array is not empty cycle through them at a show pace and show a SimpleConfirmDenyStatement for the option. Show one at a time, and transition through them.
If an option is denied, do not show it again. If an option is confirmed save it in evidenceDecision, and finish showing options. If evidenceDecision is set, do not show nothing.
objectName will show the evidence option text.

```
    SimpleConfirmDenyStatement(
        objectName: "Electric Mountain Bike",
        onConfirm: { print("Confirmed electric mountain bike") },
        onDeny: { print("Denied electric mountain bike") }
    )
    .padding(EdgeInsets(top: 0, leading: 12, bottom: 32, trailing: 12))
```

If evidenceTitle is not empty, show the title instead of cycling through options showing SimpleConfirmDenyStatement.

Support a callback onOptionConfirmed set on ClarifyEvidenceControl for the confirmation of an option. The default behavior for the callback is to set the evidenceTitle from the option. This is what ContentView should do when an option is chosen. Do not support a handleOptionConfirmed function on the viewmodel.


## RecordThingViewModel

This view model keeps track of data used to describe a single thing being recorded. 
Multiple pieces of evidence can be recorded for a single thing.
Each piece of evidence is described by ML algorithms. If there is uncertainty about the recording,
the options are offered to the users, who can do a thumbs up or down to refine the evidence.

The view can be in different states:
- Full screen camera view, when no new evidence was given
- Full screen camera view with a big overlay of a recent snap/evidence, when new evidence was recorded(15 secs) very recently or options need to be clarified with the user.
- Full screen hero view of a thing with a hole showing focus of camera preview
- Black screen with spotlight moving around showing camera preview highlights and suggestions
- Full screen illustration with a hole for scanning ID card/passport
- Full screen illustration with a hole for scanning QR code
- 

If evidence options are shown, checkbox tasks are silenced.
