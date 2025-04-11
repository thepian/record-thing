# View Models

## EvidencePiece

This represents 

- Image or Video Clip.
- evidenceOptions
- evidenceDecision
- evidenceTitle


## EvidenceViewModel

- checkboxItems: Types of evidence the user should scan
- pieces: list of EvidencePiece
- currentPiece: Identifies which of the pieces is the current one.
- focusMode
- evidenceOptions: computed as the evidenceOptions for the currentPiece
- evidenceDecision: computed as the evidenceDecision for the currentPiece
- evidenceTitle: computed as the evidenceTitle for the currentPiece
- reviewing: Evidence Pieces are shown in a Carousel to allow browsing. Checkbox actions are suppressed. Transition of to and from reviewing mode is animated.

Setting evidenceOptions, evidenceDecision, evidenceTitle on EvidenceViewModel will apply changes to the current evidence piece.
