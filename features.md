- [] Написать тест на скролл
- [] [2] Пофиксить ситуацию, когда загрузка изоображений требует времени и отправляется дополнительный запрос
- [] [2+] Подебажить перфоманс
- [] [3] Display color while photo is loading
- [] [3] Display color if photo can not be loaded
- [] [3] Fade in animation when image is actually loaded
- [] [3] Добавить *Html.keyed*
- [] [3] Animation opening and closing modals
- [] [4] a11y modal slider with animations - touch and pointer events & *close button*
- [] [5] load webp or fallback to jpeg (check if there are any other options and for retina too)
- [] [6] host on zeit/vercel
- [] [7] setup github actions to run tests
- [] [8] Dynamic limit
- [] [9] search?
- [] [10] Html.lazy
- [] lazy attribute for img and width & height
- [] setup elm-tests

# Бесконечный скролл
Проблема с IO в том, что мы отправляем запрос на картинки только в момент когда мы доскролили до конца, хотя следовало бы начинать подгрузку чуть раньше


# Динамический лимит
Есть несколько опций
getViewport - позволяет определить размеры страницы. Можно вызывать на старте приложения
- Передавать как флаги, чтобы элм сразу начал грузить картинки?
Как поступить с ресайзом? Повесить листенер https://package.elm-lang.org/packages/elm/browser/latest/Browser-Events#onResize и добавить дебаунсер

```elm
import Browser.Events as E

type Msg
  = GotNewWidth Int

subscriptions : model -> Cmd Msg
subscriptions _ =
  E.onResize (\w h -> GotNewWidth w)
  ```