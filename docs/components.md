
## DesignSystemSetup

Components use common design system properties. The components have a local variable `designSystem` that can be passed via the View Model.

## SimpleCameraView

The SimpleCameraView shows a preview of the camera feed if frames are or have been captured by CaptureService. The latest `frame` is held by the CaptureService.
The frame is oriented to reflect the rotation of the device when running on iOS. When showing a Front facing camera it is mirrored to seem natural to the user.

If no frame is present a background image is shown based on loading asset named by `cameraViewModel?.bgImageSet` in the RecordLib module Assets.

Background Image

- Keep the aspect ratio
- Fill the background
- Make sure it doesn't overflow the component borders
- Show as much of the background image as possible


## CameraDrivenView

For macOS I want to constrain the App Window size to something resonable. Set good defaults in the CameraViewModel and constrain the frame using those.
These should be defined in the DesignSystemSetup

Apply alwaysDiscardsLateVideoFrames to AVCaptureVideoDataOutput in CaptureService.

Extend CaptureService with a listener that detects device movement by accelerometer or change in camera input. If there has been no movement for a given amount of seconds pause the capture. When there is movement, resume the capture.


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

## EvidenceCarousel

View that shows an interactive carousel of images, documents and video clips. It lays out pieces horizontally. The current piece is shown in the center. Other pieces are faded. Pieces cut off by the edges are highly faded out. It will be rendered on a darkened background when used, but the darkened background isn't part of the EvidenceCarousel.
The user can pan through the evidence. A list of evidence is kept in RecordedThingViewModel.
The current evidence is also determined by the view model.

EvidenceCarousel(viewModel: RecordedThingViewModel)

Multiple previews show a range of configurations, including 4 pieces of evidence

Use library assets for preview sample evidence:

- sample_video
- professional_DSLR_camera
- thepia_a_high-end_electric_mountain_bike_1
- box_with_a_Swiss_watch_with_standing_on_a_coffee_table


## EvidenceReview

View that shows an interactive carousel of evidence.

When evidence has been recorded, the evidence is shown as an overlay within CameraDrivenView.
The overlay doesn't take up the full screen. It uses most of the top two thirds of the screen, showing a scaled recording with a white border. This EvidenceReview is also used to cycle through evidence when the ImageCardStack is pressed. The EvidenceReview is showing the RecordedThingViewModel.evidenceReviewImage or RecordedThingViewModel.evidenceReviewClip.
The width/height of the EvidenceReview is determined by setup in DesignSystemSetup.

EvidenceReview(viewModel: RecordedThingViewModel)

`focusMode` highlights the current piece of evidence and fades out the other pieces that are partially shown. It disables swiping to other pieces of evidence. `focusMode` is used to force the user to respond to the ConfirmDenyStatements for the piece of evidence.

The EvidenceReview shows a single piece of evidence in focus(horizontally centered) with other pieces of evidence shown partially left and right.


## RecordedStackAndRequirementsView

The Image Stack can be expanded or collapsed by toggling the ImageStack. It is reflected as reviewing state in RecordedThingViewModel. This can be done by tapping or swiping up/down depending on the current reviewing state.
The Carousel shows the expanded state of Evidence Pieces.
The Image Stack represents the collapsed state.

### RecordedStackAndRequirementsView Carousel

CardViews shown within Carousel can be dragged downwards. The path followed will be on a trajectory gravitating towards bottom right. The transition away from reviewing mode should animate all cards in the direction of the bottom right corner.

Dragging of Carousel Cards will be either horizontal or vertical. 
Dragging a card horizontally will change the current evidence piece. The other cards will snap into place to reflect the new viewModel value of currentPiece.
Dragging a card up is not possible.
Dragging a card down will trigger the end of reviewing mode at a certain threshold.
Gestures must have precise effects at a level of quality befitting of Apple Design Awards.


## DeveloperSidebar (RecordLib/Developer)

When shown on an iPad, the DeveloperSidebar is permanently shown at the top or to the left of the ContentView. It gives access to state information about the CaptureService, CameraViewModel and Model.

The DeveloperSidebar is also shown in BrowseNavigationView at the tail of the NavigationSplitView Toolbar. 

## CameraSubduedSwitcher (RecordLib/Developer)

The CameraSubduedSwitcher toggles CaptureService.isSubdued. The switcher is shown in the ContentView.withSidebarView sidebar.

A toggle is added to the sidebar for enabling/disabling motion detection driven pausing of the capture session.


### Reset Database & Update Database buttons

The DeveloperSidebar has three buttons.

"Reload Database" is a button that calls AppDatasource instance method `reloadDatabase`.

"Reset Database" is a button that calls AppDatasource instance method `resetDatabase`. 

"Update Database" is a button that calls AppDatasource instance method `updateDatabase`. 

Create protocol AppDatasourceAPI and make AppDatasource an implementation. Refer to AppDatasourceAPI in DeveloperSidebar.

`reloadDatabase` will recreate the Blackbird database object instance and refresh the application with the new instance.

`resetDatabase` will replace the `record-thing.sqlite` in the documentsPath with the 
`default-record-thing.sqlite` from the App Resource Bundle. It will then reloadDatabase.

`updateDatabase` will refresh the translations table in  `record-thing.sqlite` in the documentsPath to overwrite with records from `default-record-thing.sqlite` from the App Resource Bundle. It will then reloadDatabase.
Make updateDatabase async and call it in a task.

Create a MockAppDatasource: AppDatasourceAPI and use it for BrowseNavigationView previews.


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


## RecordThingApp

The main view for macOS, iOS and iPadOS.

On macOS the window should be no bigger than the camera stream proportions. It should not have a dead grey area.

While the App is in the background, CaptureService pauses capture.
As the App closes the CaptureService stops capture.

AVCaptureSession resources must be released while the Application is in the background.

Apply alwaysDiscardsLateVideoFrames to AVCaptureVideoDataOutput in CaptureService.
