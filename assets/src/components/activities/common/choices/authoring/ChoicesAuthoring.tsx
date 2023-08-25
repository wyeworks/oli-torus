import React from 'react';
import { Descendant } from 'slate';
import { useAuthoringElementContext } from 'components/activities/AuthoringElementProvider';
import { AuthoringButtonConnected } from 'components/activities/common/authoring/AuthoringButton';
import { RemoveButtonConnected } from 'components/activities/common/authoring/RemoveButton';
import { Choice, makeContent } from 'components/activities/types';
import { Draggable } from 'components/common/DraggableColumn';
import { SlateOrMarkdownEditor } from 'components/editing/SlateOrMarkdownEditor';
import { toSimpleText } from 'components/editing/slateUtils';
import { DEFAULT_EDITOR, EditorType } from 'data/content/resource';
import { classNames } from 'utils/classNames';
import styles from './ChoicesAuthoring.modules.scss';

const renderChoiceIcon = (icon: any, choice: any, index: any) =>
  icon ? (
    typeof icon === 'function' ? (
      <div className={styles.choiceIcon}>{icon(choice, index)}</div>
    ) : (
      <div className={styles.choiceIcon}>{icon}</div>
    )
  ) : undefined;

interface Props {
  icon?: React.ReactNode | ((choice: Choice, index: number) => React.ReactNode);
  choices: Choice[];
  addOne: () => void;
  setAll: (choices: Choice[]) => void;
  onEdit: (id: string, content: Descendant[]) => void;
  onChangeEditorType: (id: string, editorType: EditorType) => void;
  onRemove: (id: string) => void;
  simpleText?: boolean;
  colorMap?: Map<string, string>;
}
export const Choices: React.FC<Props> = ({
  icon,
  choices,
  addOne,
  setAll,
  onEdit,
  onRemove,
  simpleText,
  colorMap,
  onChangeEditorType,
}) => {
  const { projectSlug } = useAuthoringElementContext();

  return (
    <>
      <Draggable.Column items={choices} setItems={setAll}>
        {choices.map((choice) => (
          <Draggable.Item
            key={choice.id}
            id={choice.id}
            className="mb-4"
            item={choice}
            color={colorMap?.get(choice.id)}
          >
            {(choice, index) => (
              <>
                <Draggable.DragIndicator />
                {renderChoiceIcon(icon, choice, index)}
                {simpleText ? (
                  <input
                    className="form-control"
                    placeholder="Answer choice"
                    value={toSimpleText(choice.content)}
                    onChange={(e) => onEdit(choice.id, makeContent(e.target.value).content)}
                  />
                ) : (
                  <SlateOrMarkdownEditor
                    style={{
                      flexGrow: 1,
                      cursor: 'text',
                      backgroundColor: colorMap?.get(choice.id),
                    }}
                    editMode={true}
                    editorType={choice.editor || DEFAULT_EDITOR}
                    placeholder="Answer choice"
                    content={choice.content}
                    onEdit={(content) => onEdit(choice.id, content)}
                    allowBlockElements={true}
                    onEditorTypeChange={(editor) => onChangeEditorType(choice.id, editor)}
                    projectSlug={projectSlug}
                    initialHeight={100}
                  />
                )}

                {choices.length > 1 && (
                  <div className={styles.removeButtonContainer}>
                    <RemoveButtonConnected onClick={() => onRemove(choice.id)} />
                  </div>
                )}
              </>
            )}
          </Draggable.Item>
        ))}
      </Draggable.Column>
      <AddChoiceButton icon={icon} addOne={addOne} />
    </>
  );
};

interface AddChoiceButtonProps {
  icon: Props['icon'];
  addOne: Props['addOne'];
}
const AddChoiceButton: React.FC<AddChoiceButtonProps> = ({ addOne }) => {
  return (
    <div className={styles.addChoiceContainer}>
      <AuthoringButtonConnected
        className={classNames(styles.AddChoiceButton, 'btn btn-link pl-0')}
        action={addOne}
      >
        Add choice
      </AuthoringButtonConnected>
    </div>
  );
};
