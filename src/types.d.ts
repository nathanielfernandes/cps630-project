interface ClickOutsideEvent {
  node: HTMLElement;
  clickedElement: HTMLElement;
}

interface ImageFile {
    file: File | null;
    url: string | null;
    isLoaded: boolean;
}