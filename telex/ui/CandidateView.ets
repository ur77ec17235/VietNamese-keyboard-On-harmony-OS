@Component
export struct CandidateView {
  @State private candidates: string[] = [];
  @State private selectedIndex: number = -1;

  build() {
    Column() {
      if (this.candidates.length > 0) {
        Scroll() {
          Row() {
            ForEach(this.candidates, (candidate: string, index: number) => {
              Button(candidate) {
                Text(candidate)
                  .fontSize(14)
              }
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(this.selectedIndex === index ? '#4285f4' : '#ffffff')
              .borderRadius(5)
              .onClick(() => this.selectCandidate(index))
              .margin(2)
            })
          }
          .padding(5)
        }
        .height(50)
        .backgroundColor('#f8f9fa')
      }
    }
  }

  public updateCandidates(newCandidates: string[]): void {
    this.candidates = newCandidates;
    this.selectedIndex = -1;
  }

  public clearCandidates(): void {
    this.candidates = [];
    this.selectedIndex = -1;
  }

  private selectCandidate(index: number): void {
    this.selectedIndex = index;
    const selected = this.candidates[index];

    // Dispatch candidate selected event
    console.log('Candidate selected:', selected);
  }
}