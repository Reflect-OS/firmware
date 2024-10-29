defmodule ReflectOS.Firmware.Assets do
  use Scenic.Assets.Static,
    otp_app: :reflect_os_firmware,
    sources: [
      "assets",
      "deps/scenic_fontawesome/assets",
      {:scenic, "deps/scenic/assets"}
    ],
    alias: [
      roboto_bold: "fonts/roboto-bold.ttf",
      roboto_light: "fonts/roboto-light.ttf"
    ]
end
