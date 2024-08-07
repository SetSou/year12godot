import os
from tkinter import Tk, Label, Button, filedialog
from PIL import Image, ImageTk

class SpriteResizerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Sprite Resizer")

        self.folder_path = None
        self.output_folder = None
        
        self.preview_label = Label(root)
        self.preview_label.pack()

        self.select_folder_button = Button(root, text="Select Sprite Folder", command=self.select_folder)
        self.select_folder_button.pack()

        self.select_output_folder_button = Button(root, text="Select Output Folder", command=self.select_output_folder)
        self.select_output_folder_button.pack()

        self.process_button = Button(root, text="Process Sprites", command=self.process_sprites)
        self.process_button.pack()

    def select_folder(self):
        self.folder_path = filedialog.askdirectory(title="Select Sprite Folder")
        if self.folder_path:
            self.show_preview()

    def show_preview(self):
        if self.folder_path:
            sprite_files = [f for f in os.listdir(self.folder_path) if f.lower().endswith(('png', 'jpg', 'jpeg', 'gif', 'bmp'))]
            if sprite_files:
                first_sprite_path = os.path.join(self.folder_path, sprite_files[0])
                try:
                    with Image.open(first_sprite_path) as img:
                        img.thumbnail((200, 200))  # Resize for preview
                        photo = ImageTk.PhotoImage(img)
                        self.preview_label.config(image=photo)
                        self.preview_label.image = photo
                except Exception as e:
                    print(f"Error loading image: {e}")

    def select_output_folder(self):
        self.output_folder = filedialog.askdirectory(title="Select Output Folder")

    def process_sprites(self):
        if self.folder_path and self.output_folder:
            sprite_files = [f for f in os.listdir(self.folder_path) if f.lower().endswith(('png', 'jpg', 'jpeg', 'gif', 'bmp'))]
            if not sprite_files:
                print("No sprite images found.")
                return

            max_width, max_height = 0, 0
            sprites = []

            for sprite_file in sprite_files:
                sprite_path = os.path.join(self.folder_path, sprite_file)
                try:
                    with Image.open(sprite_path) as img:
                        width, height = img.size
                        max_width = max(max_width, width)
                        max_height = max(max_height, height)
                        sprites.append((sprite_file, img.copy()))  # Use img.copy() to avoid issues
                except Exception as e:
                    print(f"Error processing image {sprite_file}: {e}")

            for sprite_file, img in sprites:
                new_img = Image.new("RGBA", (max_width, max_height), (0, 0, 0, 0))
                img = img.convert("RGBA")
                x_offset = (max_width - img.width) // 2
                y_offset = max_height - img.height
                new_img.paste(img, (x_offset, y_offset), img)
                output_path = os.path.join(self.output_folder, sprite_file)
                try:
                    new_img.save(output_path)
                except Exception as e:
                    print(f"Error saving image {sprite_file}: {e}")

            print(f"Processing complete. Sprites saved to {self.output_folder}.")

if __name__ == "__main__":
    root = Tk()
    app = SpriteResizerApp(root)
    root.mainloop()
