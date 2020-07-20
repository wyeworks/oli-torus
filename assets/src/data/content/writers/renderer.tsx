import { ContentWriter } from './writer';
import { HtmlParser } from './html';
import { RichText } from 'components/activities/types';
import { defaultWriterContext } from './context';

interface Props {
  text: RichText;
}
export const HtmlContentModelRenderer = ({ text } : Props) => <div dangerouslySetInnerHTML={{
  __html: new ContentWriter().render(defaultWriterContext(), text.model, new HtmlParser()),
}} />;
