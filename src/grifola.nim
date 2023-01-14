import std/options
import std/os
import std/strformat

import nigui
import pixie


const
  toolName = "Grifola"
  toolVersion = "0.1.0"


type
  ImageView = ref object of ControlImpl
    image: nigui.Image

  GrifolaObj = object
    window: Window
    imageView: ImageView
    labelFilePath: Label
    textBoxFilePath: TextBox
    buttonFileBrowse: Button
    buttonHelp: Button

  Grifola = ref GrifolaObj


method handleDrawEvent(self: ImageView, event: DrawEvent) =
  let canvas = event.control.canvas
  canvas.fill()
  canvas.drawImage(self.image, 0, 0, self.width.scaleToDpi, self.height.scaleToDpi)


method handleClickEvent(self: ImageView, event: ClickEvent) =
  procCall self.ControlImpl.handleClickEvent(event)


proc newImageView(image: nigui.Image, width, height: int): ImageView =
  let imageView = ImageView(image: image)
  imageView.init()

  imageView.width = width.scaleToDpi
  imageView.height = height.scaleToDpi

  imageView.image.resize(width.scaleToDpi, height.scaleToDpi)
  imageView.image.canvas.areaColor = rgb(0, 0, 0, 0)

  imageView


proc openImage(filePath: string): Option[pixie.common.Image] =
  if filePath.fileExists():
    try:
      let image = filePath.readImage()
      some(image)
    except PixieError as error:
      echo error.msg
      none(pixie.Image)
  else:
    none(pixie.Image)


proc drawPixels(canvas: nigui.Canvas, image: pixie.common.Image) =
  let data = image.data
  for i in 0..<image.width * image.height:
    let
      x = i mod image.width
      y = i div image.width

      pixelColor = data[i]
      r = pixelColor.r.byte
      g = pixelColor.g.byte
      b = pixelColor.b.byte
      a = pixelColor.a.byte
      color = rgb(r, g, b, a)

    canvas.setPixel(x, y, color)


proc setImage(grifola: Grifola, filePath: string) =
  let res = filePath.openImage()
  if res.isSome():
    let
      source = res.get()

    grifola.imageView.width = source.width.scaleToDpi
    grifola.imageView.height = source.height.scaleToDpi

    grifola.imageView.image.resize(source.width.scaleToDpi, source.height.scaleToDpi)
    grifola.imageView.image.canvas.drawPixels(source)
    grifola.imageView.forceRedraw()

    echo "Set image"
  else:
    let errorMessage = fmt"Did not read the file: {filePath}"
    grifola.window.alert(errorMessage)


proc initLayout(grifola: Grifola): Grifola =
  grifola.window.width = 640.scaleToDpi
  grifola.window.height = 480.scaleToDpi

  let
    vContainer = newLayoutContainer(Layout_Vertical)
    hContainerFilePath = newLayoutContainer(Layout_Horizontal)
    hContainerButtonBox = newLayoutContainer(Layout_Horizontal)

  vContainer.add(grifola.imageView)

  hContainerFilePath.add(grifola.labelFilePath)
  hContainerFilePath.add(grifola.textBoxFilePath)
  hContainerFilePath.add(grifola.buttonFileBrowse)
  vContainer.add(hContainerFilePath)

  hContainerButtonBox.add(grifola.buttonHelp)
  vContainer.add(hContainerButtonBox)

  grifola.window.add(vContainer)

  grifola


proc initCallback(grifola: Grifola): Grifola =
  grifola.window.onKeyDown = proc(event: KeyboardEvent) =
    if Key_Escape.isDown():
      app.quit()

  grifola.textBoxFilePath.onKeyDown = proc(event: KeyboardEvent) =
    if Key_Return.isDown():
      let filePath = grifola.textBoxFilePath.text
      grifola.setImage(filePath)

  grifola.buttonFileBrowse.onClick = proc(event: ClickEvent) =
    let dialog = newOpenFileDialog()
    dialog.title = "Open a image file"
    dialog.multiple = false

    let currentFilePath = grifola.textBoxFilePath.text
    if currentFilePath != "" and currentFilePath.fileExists():
      dialog.directory = currentFilePath.parentDir()

    dialog.run()

    if dialog.files.len > 0:
      let filePath = dialog.files[0]
      grifola.textBoxFilePath.text = filePath
      grifola.setImage(filePath)

  grifola


proc show(grifola: Grifola) =
  grifola.window.show()


proc main(): cint =
  app.init()

  let grifola = Grifola(
    window: newWindow(fmt"{toolName} - v{toolVersion}"),
    imageView: newImageView(nigui.newImage(), 256, 256),
    labelFilePath: newLabel("File Path"),
    textBoxFilePath: newTextBox(""),
    buttonFileBrowse: newButton("..."),
    buttonHelp: newButton("Help")
  )
  .initLayout()
  .initCallback()

  grifola.show()

  app.run()


when isMainModule:
  quit(main())
